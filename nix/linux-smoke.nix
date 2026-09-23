# Linux 桌面无头 UI smoke（非支援平台）。
#
# 为何不用 Xvfb：nixpkgs 的 Xvfb 根本不含 GLX（`Extension "GLX" is not recognized`），
# 而 Flutter Linux embedder 需要 GL，Xvfb 下必然报「没有可用的 GL 实现」。
# 这里改用 Weston 的 headless backend（Wayland）——无头、能跑 GL（llvmpipe）。
#
# bundle 本身已自带 mesa/libglvnd 与 GL 环境（见 nix/linux.nix），这里只提供
# 虚拟合成器并强制软件渲染，让无头/CI 不依赖 GPU/DRM。
{
  pkgsFlutter,
  linuxDebug,
}:
pkgsFlutter.writeShellApplication {
  name = "beecount-linux-smoke";
  runtimeInputs = [ pkgsFlutter.weston ];
  text = ''
    export LIBGL_ALWAYS_SOFTWARE=1

    runtime_dir="$(mktemp -d)"
    chmod 700 "$runtime_dir"
    export XDG_RUNTIME_DIR="$runtime_dir"

    socket="beecount-smoke"
    weston_pid=""
    app_pid=""
    cleanup() {
      if [ -n "$app_pid" ]; then
        kill "$app_pid" 2>/dev/null || true
      fi
      if [ -n "$weston_pid" ]; then
        kill "$weston_pid" 2>/dev/null || true
      fi
      rm -rf "$runtime_dir"
    }
    trap cleanup EXIT INT TERM

    # headless 输出给一个桌面尺寸，让 app 的手机比例视窗有合理的预设大小。
    weston --backend=headless-backend.so --socket="$socket" \
      --width=1920 --height=1080 --idle-time=0 --log=/dev/null &
    weston_pid=$!

    # 等合成器 socket 就绪。
    for _ in $(seq 1 100); do
      if [ -S "$runtime_dir/$socket" ]; then
        break
      fi
      sleep 0.1
    done

    export WAYLAND_DISPLAY="$socket"
    export GDK_BACKEND=wayland

    "${linuxDebug}/bin/beecount" "$@" &
    app_pid=$!
    wait "$app_pid"
  '';
}

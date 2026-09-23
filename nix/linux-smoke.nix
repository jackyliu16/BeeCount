# Linux 桌面无头 UI smoke（非支援平台）。
#
# 为什么要自带 mesa / libglvnd：
#   `nix build .#linux` 出来的 bundle 只带 GTK，不带 GL。裸 Xvfb 没有 GLX 实现，
#   Flutter 会打印「没有可用的 GL 实现」并退化成空白窗口（GTK 拿不到 GLArea）。
#   这里用 pkgsFlutter 的 mesa + libglvnd（与 bundle 同一个 nixpkgs 实例，
#   避免 glibc ABI 漂移），并强制 llvmpipe 软件渲染。
#
# 真实桌面预览请用 `nix run .#linux-run`（走宿主 GPU），不需要本包装器。
{
  pkgsFlutter,
  linuxDebug,
}:
let
  mesa = pkgsFlutter.mesa;
  libglvnd = pkgsFlutter.libglvnd;
in
pkgsFlutter.writeShellApplication {
  name = "beecount-linux-smoke";
  # xvfb-run 已把 xorg.xvfb / xauth / getopt 等包进自己的 PATH。
  runtimeInputs = [ pkgsFlutter.xvfb-run ];
  text = ''
    export LIBGL_ALWAYS_SOFTWARE=1
    export GALLIUM_DRIVER=llvmpipe
    export LIBGLX_VENDOR_LIBRARY_NAME=mesa
    export LIBGL_DRIVERS_PATH="${mesa}/lib/dri"
    export __EGL_VENDOR_LIBRARY_DIRS="${mesa}/share/glvnd/egl_vendor.d"
    export LD_LIBRARY_PATH="${libglvnd}/lib:${mesa}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

    exec xvfb-run -a -s "-screen 0 1280x800x24 +extension GLX" \
      "${linuxDebug}/bin/beecount" "$@"
  '';
}

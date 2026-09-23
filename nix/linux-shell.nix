# Linux 桌面互动开发环境（非支援平台）。
#
# 提供密封 Flutter + sqlite + GL 栈，让 `flutter pub get && flutter run -d linux`
# 可以做带 hot reload 的开发预览。UI smoke 用 `nix run .#linux-smoke` 即可。
#
# 为什么要塞 mesa/libglvnd：`flutter build linux`（非 Nix wrapper）产出的 bundle
# 在运行期找不到 GL——宿主 /run/opengl-driver 的 mesa 与密封工具链的 glibc ABI
# 不一致，会报「没有可用的 GL 实现」。这里把同一 nixpkgs 实例的 mesa + libglvnd
# 放进 shell 并设好 vendor/DRI 路径。
{
  pkgsFlutter,
  hermeticFlutter,
  sqliteAmalgamation,
}:
let
  lib = pkgsFlutter.lib;
  mesa = pkgsFlutter.mesa;
  libglvnd = pkgsFlutter.libglvnd;
in
pkgsFlutter.mkShell {
  name = "beecount-linux";

  packages = [
    hermeticFlutter.wrapped # 密封 Flutter（wrapper 已带 cmake/ninja/clang/GTK pkg-config）
    pkgsFlutter.sqlite # 运行期 libsqlite3.so（drift）
    mesa # GL 实现
    libglvnd # GL 派发层（libEGL/libGL/libGLX）
    pkgsFlutter.git
    pkgsFlutter.which
  ];

  # 供 linux/CMakeLists.txt 覆写 sqlite3_flutter_libs 的 FetchContent 来源。
  BEECOUNT_SQLITE3_SOURCE_DIR = sqliteAmalgamation;

  shellHook = ''
    # dart:ffi 用 DynamicLibrary.open('libsqlite3.so')，不吃 RUNPATH；
    # 同理 GL 与 sqlite 都要靠 LD_LIBRARY_PATH 才找得到。
    export LD_LIBRARY_PATH="${
      lib.makeLibraryPath [
        pkgsFlutter.sqlite
        mesa
        libglvnd
      ]
    }''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

    # 让 libglvnd 在自带 mesa 里找 vendor / DRI 驱动，而不是宿主
    # /run/opengl-driver（那是系统 glibc 编的，ABI 不合）。
    export LIBGLX_VENDOR_LIBRARY_NAME="''${LIBGLX_VENDOR_LIBRARY_NAME:-mesa}"
    export LIBGL_DRIVERS_PATH="''${LIBGL_DRIVERS_PATH:-${mesa}/lib/dri}"
    export __EGL_VENDOR_LIBRARY_DIRS="''${__EGL_VENDOR_LIBRARY_DIRS:-${mesa}/share/glvnd/egl_vendor.d}"

    # 幂等启用桌面设定（flutter create --platforms=linux 需要）。
    flutter config --enable-linux-desktop >/dev/null 2>&1 || true

    echo "[beecount] Linux 桌面预览环境（非支援平台）"
    echo "[beecount]   未实作 Linux 的插件会丢 MissingPluginException"
    echo "[beecount]   flutter pub get && flutter run -d linux"
  '';
}

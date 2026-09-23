# Linux 桌面互动开发环境（非支援平台）。
#
# 提供密封 Flutter + 系统 sqlite，让 `flutter pub get && flutter run -d linux`
# 可以做带 hot reload 的开发预览。UI smoke 用 `nix run .#linux-run` 即可。
{
  pkgsFlutter,
  hermeticFlutter,
  sqliteAmalgamation,
}:
let
  lib = pkgsFlutter.lib;
in
pkgsFlutter.mkShell {
  name = "beecount-linux";

  packages = [
    hermeticFlutter.wrapped # 密封 Flutter（wrapper 已带 cmake/ninja/clang/GTK pkg-config）
    pkgsFlutter.sqlite # 运行期 libsqlite3.so（drift）
    pkgsFlutter.git
    pkgsFlutter.which
  ];

  # 供 linux/CMakeLists.txt 覆写 sqlite3_flutter_libs 的 FetchContent 来源。
  BEECOUNT_SQLITE3_SOURCE_DIR = sqliteAmalgamation;

  shellHook = ''
    # dart:ffi 用 DynamicLibrary.open('libsqlite3.so')，不吃 RUNPATH。
    export LD_LIBRARY_PATH="${
      lib.makeLibraryPath [ pkgsFlutter.sqlite ]
    }''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

    # 幂等启用桌面设定（flutter create --platforms=linux 需要）。
    flutter config --enable-linux-desktop >/dev/null 2>&1 || true

    echo "[beecount] Linux 桌面预览环境（非支援平台）"
    echo "[beecount]   未实作 Linux 的插件会丢 MissingPluginException"
    echo "[beecount]   flutter pub get && flutter run -d linux"
  '';
}

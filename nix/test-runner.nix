# 密封单测运行器：在仓库根目录用密封 Flutter 跑 `flutter test`（--no-pub，
# 复用 devShell 里 `fvm flutter pub get` 或 `nix run .#flutter -- pub get` 生成的
# .dart_tool/package_config.json）。
#
# 存在的理由：`flutter test` 会经 dlopen 载入 libsqlite3.so（drift/sqlite3 相关用例），
# 直接 `nix run .#flutter -- test` 会因动态库不在 loader 路径而失败；这里补上
# LD_LIBRARY_PATH 与 HOME/PUB_CACHE 的默认值。
{
  pkgs,
  pkgsFlutter,
  hermeticFlutter,
}:
let
  lib = pkgsFlutter.lib;
in
pkgs.writeShellApplication {
  name = "flutter-test";
  runtimeInputs = [ pkgsFlutter.git ];
  text = ''
    if [ ! -f pubspec.yaml ]; then
      echo "[beecount] 请在仓库根目录运行（找不到 pubspec.yaml）" >&2
      exit 1
    fi

    if [ ! -f .dart_tool/package_config.json ]; then
      echo "[beecount] 缺少 .dart_tool/package_config.json，先生成依赖：" >&2
      echo "[beecount]   nix run .#flutter -- pub get" >&2
      exit 1
    fi

    export PUB_CACHE="''${PUB_CACHE:-''${HOME:-$TMPDIR}/.pub-cache}"
    export TZ="''${TZ:-UTC}"
    export LD_LIBRARY_PATH="${
      lib.makeLibraryPath [ pkgsFlutter.sqlite ]
    }''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

    exec "${hermeticFlutter.wrapped}/bin/flutter" test --no-pub "$@"
  '';
}

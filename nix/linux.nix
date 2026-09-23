# Linux 桌面预览目标（非支援平台，仅做 UI smoke / 开发预览）。
#
# 产出 debug 与 release 两个 bundle。定位与 Android/iOS 不同：
#   - 不是支援平台；没有 Linux 实作的插件（permission_handler / local_auth /
#     webview_flutter / gal / image_cropper / flutter_image_compress /
#     in_app_review / quick_actions / open_filex / home_widget /
#     in_app_purchase_storekit …）在运行期只会丢 MissingPluginException。
#   - 不入门禁（nix/checks.nix 与本档互不影响）。
#
# 注意：全程只使用 pkgsFlutter（nixos-25.05）这一个 nixpkgs 实例，避免 closure/ABI 漂移。
{
  pkgsFlutter,
  hermeticFlutter,
  src,
  # 已实体化的 pubspec.lock（pub2nix 会在评估期检查它）。
  autoPubspecLock,
}:
let
  lib = pkgsFlutter.lib;

  flutterDir = pkgsFlutter.path + "/pkgs/development/compilers/flutter";

  # 复用 nixpkgs 的 buildFlutterApplication，但绑定到密封 wrapper。
  buildFlutterApplication =
    pkgsFlutter.callPackage (flutterDir + "/build-support/build-flutter-application.nix")
      {
        flutter = hermeticFlutter.wrapped;
      };

  # sqlite3_flutter_libs 的 linux 外挂用 CMake FetchContent 从网络下载
  # sqlite-autoconf-*.tar.gz；Nix sandbox 无网，会直接建置失败。
  # 这里改用 nixpkgs sqlite 的 amalgamation 源（本身可从 cache.nixos.org 取代，
  # 无需新增 fetchurl hash），由 linux/CMakeLists.txt 读取
  # BEECOUNT_SQLITE3_SOURCE_DIR 覆写 FetchContent 来源。
  sqlite = pkgsFlutter.sqlite;
  sqliteAmalgamation =
    pkgsFlutter.runCommand "sqlite3-amalgamation-${sqlite.version}"
      {
        nativeBuildInputs = [ pkgsFlutter.gnutar ];
      }
      ''
        mkdir -p "$out"
        tar xf ${sqlite.src} -C "$out" --strip-components=1
        test -f "$out/sqlite3.c"
      '';

  mkLinux =
    { mode }:
    buildFlutterApplication ({
      pname = "beecount-linux" + lib.optionalString (mode != "release") "-${mode}";
      version = "0.0.1";

      inherit src autoPubspecLock;
      targetFlutterPlatform = "linux";
      flutterMode = mode;

      nativeBuildInputs = [ pkgsFlutter.git ];
      buildInputs = [ sqlite ];
      # dart:ffi 用 DynamicLibrary.open('libsqlite3.so')，不吃 RUNPATH；
      # dart-fixup-hook 会把这里的 lib 目录包进 $out/bin/* 的 LD_LIBRARY_PATH。
      runtimeDependencies = [ sqlite ];

      # 刻意覆写 nixpkgs 预设的 `--split-debug-info="$debug"`：
      # debug 模式不需要（且未必支援）split-debug-info，两种模式共用同一条
      # buildPhase 可避免分歧。installPhase / outputs 沿用 nixpkgs 预设。
      buildPhase = ''
        runHook preBuild
        flutter build linux --${mode}
        runHook postBuild
      '';

      # 因为 buildPhase 不再传 --split-debug-info，linux target 声明的 `debug`
      # output 目录不会自动生成；这里补一个空目录满足 Nix 的 output 检查。
      postInstall = ''
        mkdir -p "$debug"
      '';

      # 供 linux/CMakeLists.txt 覆写 sqlite3_flutter_libs 的 FetchContent 来源。
      BEECOUNT_SQLITE3_SOURCE_DIR = sqliteAmalgamation;

      meta = {
        description = "BeeCount Linux desktop preview (${mode}; not a supported platform)";
        platforms = lib.platforms.linux;
      };
    });
in
{
  debug = mkLinux { mode = "debug"; };
  release = mkLinux { mode = "release"; };
  inherit sqliteAmalgamation;
}

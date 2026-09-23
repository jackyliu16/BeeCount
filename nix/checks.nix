# 密封层 checks：用密闭 Flutter 3.27.3 + Nix store 里的 pub 依赖，
# 离线运行 flutter analyze / flutter test。
{
  # 注意：全程只使用 pkgsFlutter（nixos-25.05）这一个 nixpkgs 实例，
  # 不得混入主 nixpkgs（unstable）的衍生品，避免 closure/ABI 漂移。
  pkgsFlutter,
  hermeticFlutter,
  # src 为收窄后的建置源；autoPubspecLock 必须是已实体化的 pubspec.lock
  # （pub2nix 会用 builtins.pathExists 检查它，而收窄后的路径在评估期尚未实体化）。
  src,
  autoPubspecLock,
}:
let
  lib = pkgsFlutter.lib;

  flutterDir = pkgsFlutter.path + "/pkgs/development/compilers/flutter";

  # 复用 nixpkgs 的 buildFlutterApplication，但绑定到我们收窄过的 wrapper
  # （supportedTargetFlutterPlatforms = [ universal linux ]），
  # 避免为 analyze/test 下载 web / android 引擎产物。
  buildFlutterApplication =
    pkgsFlutter.callPackage (flutterDir + "/build-support/build-flutter-application.nix")
      {
        flutter = hermeticFlutter.wrapped;
      };

  mkCheck =
    {
      name,
      platform,
      command,
    }:
    buildFlutterApplication {
      pname = "beecount-${name}";
      version = "0.0.1";

      inherit src;
      targetFlutterPlatform = platform;
      # pub 依赖经 pub2nix 从 Nix store 提供（IFD；flake 内允许）。
      inherit autoPubspecLock;

      nativeBuildInputs = [ pkgsFlutter.git ];
      # drift/sqlite3_flutter_libs 在 `flutter test` 里通过动态库加载 libsqlite3.so。
      # 与上方输入一致，只用同一个 nixpkgs 实例提供的 sqlite。
      buildInputs = [ pkgsFlutter.sqlite ];

      buildPhase = ''
        runHook preBuild
        export HOME="$TMPDIR"
        export PUB_CACHE="$TMPDIR/.pub-cache"
        # `flutter test` 经 dlopen 载入 libsqlite3.so，需显式加入 loader 路径。
        export LD_LIBRARY_PATH="${lib.makeLibraryPath [ pkgsFlutter.sqlite ]}:''${LD_LIBRARY_PATH:-}"
        ${command}
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        mkdir -p $out
        echo ok > $out/stamp
        # linux 目标会额外声明 `debug` output，必须产出，否则 Nix 报错。
        if [ -n "''${debug:-}" ]; then
          mkdir -p "$debug"
        fi
        runHook postInstall
      '';

      meta = {
        description = "BeeCount hermetic ${name} check";
        platforms = lib.platforms.linux;
      };
    };
in
{
  analyze = mkCheck {
    name = "analyze";
    # analyze 无需 linux 桌面引擎产物，universal 即可。
    platform = "universal";
    command = "flutter analyze --no-pub";
  };

  test = mkCheck {
    name = "test";
    # flutter test 需要 linux 引擎产物（flutter_tester）。
    platform = "linux";
    command = "flutter test --no-pub";
  };
}

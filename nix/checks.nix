# 密封层 checks：用密闭 Flutter 3.27.3 + Nix store 里的 pub 依赖，
# 离线运行 flutter analyze / flutter test / dart test。
{
  # 注意：全程只使用 pkgsFlutter（nixos-25.05）这一个 nixpkgs 实例，
  # 不得混入主 nixpkgs（unstable）的衍生品，避免 closure/ABI 漂移。
  pkgsFlutter,
  hermeticFlutter,
  # src 为收窄后的建置源；autoPubspecLock 必须是已实体化的 pubspec.lock
  # （pub2nix 会用 builtins.pathExists 检查它，而收窄后的路径在评估期尚未实体化）。
  src,
  autoPubspecLock,
  # packages/agentcore 是纯 Dart 包，用「它自己的 pubspec.lock」独立校验（见 mkDartCheck）。
  agentcoreSrc,
  agentcorePubspecLock,
}:
let
  lib = pkgsFlutter.lib;

  flutterDir = pkgsFlutter.path + "/pkgs/development/compilers/flutter";

  # 复用 nixpkgs 的 buildFlutterApplication，但绑定到我们收窄过的 wrapper
  # （supportedTargetFlutterPlatforms = [ universal linux android ]），
  # 避免为 analyze/test 下载 web / ios 引擎产物。
  buildFlutterApplication =
    pkgsFlutter.callPackage (flutterDir + "/build-support/build-flutter-application.nix")
      {
        flutter = hermeticFlutter.wrapped;
      };

  # 密封 Dart SDK 3.6.1（与 .fvmrc 的 Flutter 3.27.3 捆绑的版本一致）。
  # 不能直接用 nixos-25.05 的 pkgs.dart（3.7.3）：packages/agentcore 约束 sdk <3.7.0。
  sealedDart = hermeticFlutter.wrapped.dart;

  buildDartApplication = pkgsFlutter.buildDartApplication.override {
    dart = sealedDart;
  };

  # 只用根 lock 就能解析的嵌套包测试目录：
  # 它们的 import 只有 flutter_test / path 依赖 / crypto，全部在根 pubspec.lock 内。
  # （packages/agentcore 用 package:test，见 mkDartCheck 的注释。）
  flutterPackageTests = [
    "packages/flutter_cloud_sync/test"
    "packages/flutter_cloud_sync_supabase/test"
  ];

  # 已知红灯的嵌套包测试：packages/flutter_cloud_sync_webdav/test 里有 5 个用例
  # 仍在断言「邮箱登录 / 重置密码 / 重发验证邮件」旧行为，而 WebDAVAuthService 现已
  # 改为抛 UnsupportedError（见 lib/src/webdav_auth_service.dart:52/65/70）。
  # 产物不在 checks 里，避免永久红门禁；等上游对齐后再并入 flutterPackageTests。
  knownFailingFlutterPackageTests = [ "packages/flutter_cloud_sync_webdav/test" ];

  # 测试集合变化时宁可直接失败，也不要静默少跑测试。
  nestedTestsGuard = tests: ''
    for d in ${lib.concatStringsSep " " tests}; do
      if [ ! -d "$d" ]; then
        echo "BeeCount: 缺少嵌套包测试目录 $d（若已移动/删除，请同步更新 nix/checks.nix）" >&2
        exit 1
      fi
    done
  '';

  flutterTestCommand = tests: ''
    ${nestedTestsGuard tests}
    flutter test --no-pub ${lib.concatStringsSep " " tests}
  '';

  # 确定性：sandbox 里 TZ/LANG 未定义会让本地与 CI 的结果分歧，显式钉住。
  determinismEnv = {
    TZ = "UTC";
    LC_ALL = "C.UTF-8";
    LANG = "C.UTF-8";
  };

  installStamp = ''
    runHook preInstall
    mkdir -p $out
    echo ok > $out/stamp
    runHook postInstall
  '';

  mkCheck =
    {
      name,
      platform,
      command,
    }:
    buildFlutterApplication (
      {
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
      }
      // determinismEnv
    );

  # 纯 Dart 包的密封校验：用该包自己的 pubspec.lock + 密封 Dart SDK 跑 `dart test`。
  #
  # 为什么不并进根 pubspec.yaml 的 dev_dependencies：
  # 根 lock 的 flutter_test 钉住 test_api 0.7.2 → test_core 最高 0.6.5
  # → 强制 analyzer <7.0.0 → drift_dev 2.28 需要 analyzer ^7 → 连带把运行时依赖
  # drift 从 2.28.x 降到 2.26.x。agentcore 自己的 lock（test 1.26.3 / test_core 0.6.12
  # / analyzer 7.7.1）自洽，独立成派生即可两全。
  mkDartCheck =
    {
      name,
      checkSrc,
      checkPubspecLock,
      command,
    }:
    buildDartApplication (
      {
        pname = "beecount-${name}";
        version = "0.0.1";

        src = checkSrc;
        autoPubspecLock = checkPubspecLock;

        dontDartBuild = true;
        dontDartInstall = true;

        buildPhase = ''
          runHook preBuild
          export HOME="$TMPDIR"
          export PUB_CACHE="$TMPDIR/.pub-cache"
          ${command}
          runHook postBuild
        '';

        installPhase = installStamp;

        meta = {
          description = "BeeCount hermetic ${name} check";
          platforms = lib.platforms.linux;
        };
      }
      // determinismEnv
    );
in
{
  analyze = mkCheck {
    name = "analyze";
    # analyze 无需 linux 桌面引擎产物，universal 即可。
    platform = "universal";
    # 只对 error 设门禁（flutter 的 --fatal-infos/--fatal-warnings 默认 true），
    # 并把范围收窄到 lib/ + test/：
    # pub2nix 会把 path 依赖装成独立 store 包，导致 `packages/flutter_cloud_sync/lib`
    # 里的相对导入与子包的 `package:flutter_cloud_sync/...` 分属两份「同名不同路径」的
    # CloudProvider 声明，产生 4 条密封环境特有的 return_of_invalid_type 伪错误。
    # 代价：嵌套包（packages/**）的 lint 本轮不在任何门禁内；agentcore 的行为由
    # test-agentcore 覆盖，其余包的 lint 留待逐包 check（需先清各自的 lint 债）。
    command = "flutter analyze --no-fatal-infos --no-fatal-warnings lib test";
  };

  test = mkCheck {
    name = "test";
    # flutter test 需要 linux 引擎产物（flutter_tester）。
    platform = "linux";
    command = flutterTestCommand ([ "test" ] ++ flutterPackageTests);
  };

  # 已知红（5 个陈旧用例，见 knownFailingFlutterPackageTests 注释）：
  # 不进 checks，保留一条命令让上游修完后能直接回归。
  test-webdav = mkCheck {
    name = "test-webdav";
    platform = "linux";
    command = flutterTestCommand knownFailingFlutterPackageTests;
  };

  # 纯 Dart 包（packages/agentcore，4 个测试文件）用 package:test，走 dart test。
  # 用 dartConfigHook 提供的 packageRun（dart --packages=.dart_tool/package_config.json
  # <test 包>/bin/test.dart）：直接调 test 包入口，绕开 `dart test` 的隐式 pub 解析
  # （沙箱无网，pub 解析会因缺 .dart_tool/pub 元数据而尝试访问 pub.dev）。
  test-agentcore = mkDartCheck {
    name = "test-agentcore";
    checkSrc = agentcoreSrc;
    checkPubspecLock = agentcorePubspecLock;
    command = "packageRun test";
  };
}

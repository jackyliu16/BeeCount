{
  description = "BeeCount — Flutter devShell (FVM) + hermetic checks (Nix flake)";

  inputs = {
    # 主 nixpkgs：提供 devShell 工具链（fvm / jdk17 / Android SDK+NDK / python 等）。
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Flutter 打包机制（mkFlutter + 3.27 血统补丁）。
    # 当前 nixpkgs 只维护 >=3.29，其补丁未必适用于 3.27.3，故单独钉 nixos-25.05。
    nixpkgs-flutter.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-flutter,
    }:
    let
      system = "x86_64-linux";
      # Android SDK/NDK 是 unfree（Google 许可）。仅作用于本 flake 的实例，
      # 不修改用户系统配置。
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          android_sdk.accept_license = true;
        };
      };
      pkgsFlutter = nixpkgs-flutter.legacyPackages.${system};
      lib = pkgs.lib;

      # 只把密封 analyze/test 真正需要的档案交给 checks，
      # 避免仅改文档 / Android / iOS / Nix 自身也触发密封层重建。
      checksSrc = lib.cleanSourceWith {
        src = self;
        filter =
          path: _type:
          let
            rel = lib.removePrefix "${toString self}/" (toString path);
          in
          !lib.any (p: rel == p || lib.hasPrefix "${p}/" rel) [
            "android"
            "ios"
            "linux"
            "docs"
            ".github"
            "nix"
            "demo"
            "preview"
            "flake.nix"
            "flake.lock"
          ];
      };

      # ---- .fvmrc 绑定：唯一事实来源，只读不写 ----
      fvmrc =
        if builtins.pathExists ./.fvmrc then
          builtins.fromJSON (builtins.readFile ./.fvmrc)
        else
          throw "BeeCount: 缺少 .fvmrc（Flutter 版本的唯一事实来源）";

      flutterVersion =
        assert lib.assertMsg (
          fvmrc ? flutter && lib.isString fvmrc.flutter
        ) "BeeCount: .fvmrc 缺少字符串字段 \"flutter\"";
        fvmrc.flutter;

      flutterDataFile = ./nix/flutter-versions + "/${flutterVersion}.json";
      flutterData =
        if builtins.pathExists flutterDataFile then
          builtins.fromJSON (builtins.readFile flutterDataFile)
        else
          throw ''
            BeeCount: 找不到密封 Flutter 版本数据 nix/flutter-versions/${flutterVersion}.json。
            .fvmrc 钉住 Flutter ${flutterVersion}，请先运行：
              nix/gen-flutter-version.sh ${flutterVersion}
            并把生成的 JSON 提交到仓库。
          '';

      hermeticFlutter = import ./nix/flutter.nix {
        inherit pkgsFlutter flutterVersion flutterData;
      };

      android = import ./nix/android.nix { inherit pkgs; };

      # 密封 Flutter 包装器：首次调用建立可写 overlay（Android/Gradle 需要）。
      flutterAndroid = import ./nix/flutter-android.nix {
        inherit pkgs flutterVersion hermeticFlutter;
      };

      devshell = import ./nix/devshell.nix { inherit pkgs flutterVersion android; };

      # 密封 Android 环境：不依赖 FVM / 本机 Flutter。
      androidShell = import ./nix/android-shell.nix {
        inherit
          pkgs
          flutterVersion
          flutterAndroid
          android
          ;
      };

      # 密封单测运行器（`nix run .#flutter-test -- test/utils`）。
      testRunner = import ./nix/test-runner.nix {
        inherit
          pkgs
          pkgsFlutter
          hermeticFlutter
          ;
      };

      # Linux 桌面预览（非支援平台；不入门禁）：debug + release 两 bundle。
      linux = import ./nix/linux.nix {
        inherit pkgsFlutter hermeticFlutter;
        src = self;
        autoPubspecLock = self + "/pubspec.lock";
      };

      # Linux 桌面互动开发 shell（密封 Flutter + 系统 sqlite）。
      linuxShell = import ./nix/linux-shell.nix {
        inherit pkgsFlutter hermeticFlutter;
        sqliteAmalgamation = linux.sqliteAmalgamation;
      };

      # Linux 桌面无头 UI smoke（Weston headless + 软件 GL，不需宿主 GPU）。
      linuxSmoke = import ./nix/linux-smoke.nix {
        inherit pkgsFlutter;
        linuxDebug = linux.debug;
      };

      checks = import ./nix/checks.nix {
        inherit pkgsFlutter hermeticFlutter;
        src = checksSrc;
        # 已实体化的 lock 源（不被收窄影响）。
        autoPubspecLock = self + "/pubspec.lock";
        # packages/agentcore 是纯 Dart 包，用自己那棵子树 + 自己的 lock 独立校验。
        agentcoreSrc = self + "/packages/agentcore";
        agentcorePubspecLock = self + "/packages/agentcore/pubspec.lock";
      };
    in
    {
      devShells.${system} = {
        default = devshell;
        android = androidShell;
        linux = linuxShell;
      };

      packages.${system} = {
        flutter = hermeticFlutter.wrapped;
        # 密封 Flutter 的 Android 包装器（可写 overlay + 密封 SDK）。
        flutter-android = flutterAndroid;
        # Android 工具链（unfree；仅作用于本 flake 实例）：供密封 SDK 做 `build apk`。
        inherit (android) androidSdk jdk17;
        inherit (checks) analyze test;
        # 纯 Dart 包（packages/agentcore）的密封测试：用其自身 pubspec.lock + 密封 Dart SDK。
        "test-agentcore" = checks.test-agentcore;
        # 已知红灯的 webdav 包测试（5 个陈旧用例）；不入门禁，仅提供一条命令回归。
        "test-webdav" = checks.test-webdav;
        # Linux 桌面预览（非支援平台）：`.#linux` 是 debug 预览，`.#linux-release` 是 release。
        linux = linux.debug;
        linux-release = linux.release;
        # 无头 UI smoke 包装器（Weston headless + 软件 GL）。
        linux-smoke = linuxSmoke;
      };

      apps.${system} = {
        flutter = {
          type = "app";
          program = "${hermeticFlutter.wrapped}/bin/flutter";
          meta.description = "BeeCount 密封 Flutter ${flutterVersion} 命令列";
        };

        flutter-android = {
          type = "app";
          program = "${flutterAndroid}/bin/flutter";
          meta.description = "BeeCount 密封 Flutter ${flutterVersion}（Android 可写包装器）";
        };

        # `nix run .#flutter-test -- test/utils`：密封 `flutter test`（单文件/单用例/目录）。
        flutter-test = {
          type = "app";
          program = "${testRunner}/bin/flutter-test";
          meta.description = "BeeCount 密封 flutter test 运行器（--no-pub，含 sqlite 运行库路径）";
        };

        # Linux 桌面预览（需显示器；GL 由 bundle 自带 mesa，无头用 `nix run .#linux-smoke`）。
        linux-run = {
          type = "app";
          program = "${linux.debug}/bin/beecount";
          meta.description = "BeeCount Linux 桌面 debug 预览（非支援平台）";
        };

        linux-release-run = {
          type = "app";
          program = "${linux.release}/bin/beecount";
          meta.description = "BeeCount Linux 桌面 release 预览（非支援平台）";
        };

        # 无头 UI smoke：Weston headless + 软件 GL（llvmpipe），不需显示器/GPU。
        linux-smoke = {
          type = "app";
          program = "${linuxSmoke}/bin/beecount-linux-smoke";
          meta.description = "BeeCount Linux 桌面无头 UI smoke（Weston headless + 软件 GL）";
        };
      };

      # `nix flake check` 门禁：密封 `test`（根 test/ + packages/*/test 中可由根 lock
      # 解析的部分）与 `test-agentcore`（纯 Dart 包，走自己的 lock + dart test）。
      # `analyze` 仅对 error 设门禁、范围 lib/ + test/（跨包分析在密封环境有
      # path-依赖类型 identity 伪错误），以 `nix build .#analyze` 提供，暂不入 checks。
      checks.${system} = {
        inherit (checks) test;
        "test-agentcore" = checks.test-agentcore;
      };

      formatter.${system} = pkgs.nixfmt;
    };
}

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

      checks = import ./nix/checks.nix {
        inherit pkgsFlutter hermeticFlutter;
        src = checksSrc;
        # 已实体化的 lock 源（不被收窄影响）。
        autoPubspecLock = self + "/pubspec.lock";
      };
    in
    {
      devShells.${system} = {
        default = devshell;
        android = androidShell;
      };

      packages.${system} = {
        flutter = hermeticFlutter.wrapped;
        # 密封 Flutter 的 Android 包装器（可写 overlay + 密封 SDK）。
        flutter-android = flutterAndroid;
        # Android 工具链（unfree；仅作用于本 flake 实例）：供密封 SDK 做 `build apk`。
        inherit (android) androidSdk jdk17;
        inherit (checks) analyze test;
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
      };

      # `nix flake check` 只把密封 `test` 作为门禁。
      # 严格 `analyze`（与 CI 的 `flutter analyze` 一致）另以
      # `nix build .#analyze` 提供；待 lint 欠债清理完再移入 checks。
      checks.${system} = {
        inherit (checks) test;
      };

      formatter.${system} = pkgs.nixfmt;
    };
}

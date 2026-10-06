# 开发层 devShell：Nix 提供工具链（含 Android SDK + JDK），Flutter 由 FVM 按 .fvmrc 下载。
#
# 注意：FVM 下载的是通用 Linux 构建，在 NixOS 上默认无法运行（NixOS 没有 FHS 动态链接器，
# /lib64/ld-linux-x86-64.so.2 是只会报错的 stub）。此时请改用密封入口
# `nix run .#flutter -- pub get` / `nix run .#flutter-test`，或在系统启用 programs.nix-ld
# 让 FVM 的 SDK 能运行。shellHook 会按实际情况给出对应提示。
{
  pkgs,
  flutterVersion,
  android,
}:
let
  python = pkgs.python3.withPackages (p: [ p.pillow ]);
in
pkgs.mkShell (
  {
    name = "beecount";

    packages = [
      pkgs.fvm
      android.jdk17
      android.androidSdk
      pkgs.android-tools # adb
      python
      pkgs.git
      pkgs.unzip
      pkgs.curl
      pkgs.which
      pkgs.pkg-config
      pkgs.cmake
      pkgs.ninja
    ];

    # .fvmrc 的唯一事实来源，透出给工具/包装脚本使用。
    FLUTTER_VERSION = flutterVersion;

    shellHook = ''
      # 1) 让 AGP 找到 Android SDK（Flutter 会自行管理 local.properties 里的 flutter.sdk）。
      if [ ! -f android/local.properties ]; then
        printf 'sdk.dir=%s\n' "$ANDROID_HOME" > android/local.properties
        echo "[beecount] 已生成 android/local.properties (sdk.dir=$ANDROID_HOME)"
      fi

      # 2) 一致性断言：FVM 解析出的 Flutter 必须与 .fvmrc 一致。
      #    「未安装」与「装了但跑不起来」要分开提示，否则 NixOS 上断言会被静默跳过。
      fvm_flutter=.fvm/flutter_sdk/bin/flutter
      if [ ! -x "$fvm_flutter" ]; then
        echo "[beecount] 尚未安装项目 Flutter SDK。首次使用请运行："
        echo "[beecount]     fvm install && fvm flutter pub get"
        echo "[beecount] 密封门禁：nix flake check（test + test-agentcore）"
        echo "[beecount] 密封单测：nix run .#flutter-test -- test/utils（单个文件/用例同样可用）"
      else
        resolved="$("$fvm_flutter" --version --machine 2>/dev/null \
          | python3 -c 'import json,sys; print(json.load(sys.stdin)["frameworkVersion"])' 2>/dev/null || true)"
        if [ -z "$resolved" ]; then
          # 装了却跑不起来：最常见是 NixOS 没启用 nix-ld，FVM 的通用 Linux SDK 起不来。
          echo "[beecount] ⚠️  .fvm/flutter_sdk 存在但无法执行，版本一致性断言已跳过。" >&2
          echo "[beecount]     常见原因：NixOS 未启用 programs.nix-ld（FVM 下载的是通用 Linux 构建，" >&2
          echo "[beecount]     需要 /lib64/ld-linux-x86-64.so.2，而 NixOS 默认只有会报错的 stub）。" >&2
          echo "[beecount]     本机可用的替代入口（不需要 FVM）：" >&2
          echo "[beecount]       nix run .#flutter -- pub get          # 依赖解析（生成 .dart_tool/package_config.json）" >&2
          echo "[beecount]       nix run .#flutter-test -- test/utils  # 密封单测（已含 sqlite 运行库路径）" >&2
          echo "[beecount]       nix run .#flutter-android -- build apk  # Android 构建（可写包装器）" >&2
          echo "[beecount]     要让 FVM 本身可用：启用 programs.nix-ld（按需补 stdenv.cc.cc.lib 等库）并重新登录。" >&2
        elif [ "$resolved" != "$FLUTTER_VERSION" ]; then
          echo "[beecount] ❌ FVM 的 Flutter ($resolved) 与 .fvmrc ($FLUTTER_VERSION) 不一致" >&2
          echo "[beecount]    修复：fvm install" >&2
          return 1
        fi
      fi
    '';
  }
  // android.env
)

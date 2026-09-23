# 开发层 devShell：Nix 提供工具链（含 Android SDK + JDK），Flutter 由 FVM 按 .fvmrc 下载。
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
      if [ -x .fvm/flutter_sdk/bin/flutter ]; then
        resolved="$(.fvm/flutter_sdk/bin/flutter --version --machine 2>/dev/null \
          | python3 -c 'import json,sys; print(json.load(sys.stdin)["frameworkVersion"])' 2>/dev/null || true)"
        if [ -n "$resolved" ] && [ "$resolved" != "$FLUTTER_VERSION" ]; then
          echo "[beecount] ❌ FVM 的 Flutter ($resolved) 与 .fvmrc ($FLUTTER_VERSION) 不一致" >&2
          echo "[beecount]    修复：fvm install" >&2
          return 1
        fi
      else
        echo "[beecount] 尚未安装项目 Flutter SDK。首次使用请运行："
        echo "[beecount]     fvm install && fvm flutter pub get"
        echo "[beecount] 密封校验可直接用：nix build .#analyze .#test"
      fi
    '';
  }
  // android.env
)

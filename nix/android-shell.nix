# 密封 Android 开发环境：密封 Flutter（含 android 引擎产物）+ Android SDK + JDK17，
# 无需 FVM、也不依赖本机 Flutter。
{
  pkgs,
  flutterVersion,
  flutterAndroid,
  android,
}:
pkgs.mkShell (
  {
    name = "beecount-android";

    packages = [
      flutterAndroid # 密封 Flutter 包装器（首次调用建立可写 overlay）
      android.androidSdk
      android.jdk17
      pkgs.android-tools # adb
      pkgs.git
      pkgs.unzip
      pkgs.curl
      pkgs.which
    ];

    # .fvmrc 的唯一事实来源（与密封数据同名绑定）。
    FLUTTER_VERSION = flutterVersion;

    shellHook = ''
      # AGP 需要 SDK 路径；flutter.sdk 由 Flutter 依 FLUTTER_ROOT（可写 overlay）写入。
      if [ ! -f android/local.properties ]; then
        printf 'sdk.dir=%s\n' "$ANDROID_HOME" > android/local.properties
        echo "[beecount] 已生成 android/local.properties (sdk.dir=$ANDROID_HOME)"
      fi
      echo "[beecount] 密封 Android 环境：Flutter $FLUTTER_VERSION + Android SDK + JDK17"
      echo "[beecount]   flutter 首次调用会建立可写 overlay，可直接：flutter build apk --flavor prod"
    '';
  }
  // android.env
)

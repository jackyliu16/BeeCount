# Android 工具链的单一来源：devShell 与 flake `packages` 共用。
# SDK / NDK / build-tools / JDK 版本一律与 android/app/build.gradle 对齐：
#   compileSdk = 36, buildTools 35.0.0, ndkVersion 27.0.12077973, JVM 17
{ pkgs }:
let
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    # 依 pub 插件模组各自声明的 compileSdk（34/35/36）全部预装；
    # app 本身是 36。缺哪个 AGP 都会尝试写入只读的 Nix store SDK 而失败。
    platformVersions = [
      "34"
      "35"
      "36"
    ];
    buildToolsVersions = [ "35.0.0" ];
    ndkVersions = [ "27.0.12077973" ];
    includeNDK = true;
  };
  androidSdk = androidComposition.androidsdk;
  androidHome = "${androidSdk}/libexec/android-sdk";
  jdk17 = pkgs.jdk17;
in
{
  inherit androidSdk jdk17;

  # 供 devShell / 建置环境使用的一致变量。
  env = {
    ANDROID_HOME = androidHome;
    ANDROID_SDK_ROOT = androidHome;
    ANDROID_NDK_ROOT = "${androidHome}/ndk-bundle";
    JAVA_HOME = "${jdk17.home}";
    # nixpkgs 手册建议：让 AGP 使用 Nix store 里已 patchelf 的 aapt2。
    GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidHome}/build-tools/35.0.0/aapt2";
  };
}

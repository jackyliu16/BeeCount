# 用 nixpkgs-flutter(nixos-25.05) 的 mkFlutter + 本仓库自备的版本数据，
# 构建与 .fvmrc 精确一致的密闭 Flutter SDK。
{
  pkgsFlutter,
  flutterVersion,
  flutterData,
}:
let
  lib = pkgsFlutter.lib;

  flutterDir = pkgsFlutter.path + "/pkgs/development/compilers/flutter";

  # "3.27.3" -> "3_27"（nixpkgs 的版本目录只到 major.minor）
  compact = builtins.replaceStrings [ "." ] [ "_" ] (lib.versions.majorMinor flutterVersion);
  versionDir = "${flutterDir}/versions/${compact}";

  patchesFrom =
    dir:
    if builtins.pathExists dir then
      map (f: dir + "/${f}") (builtins.attrNames (builtins.readDir dir))
    else
      [ ];

  # nixpkgs 自带的共享补丁 + 该 Flutter 血统的版本补丁（后者对旧版本是必需的）。
  patches = patchesFrom (flutterDir + "/patches") ++ patchesFrom (versionDir + "/patches");
  enginePatches =
    patchesFrom (flutterDir + "/engine/patches") ++ patchesFrom (versionDir + "/engine/patches");

  # 本仓库只在 x86_64-linux 上实测哈希；其他系统在 JSON 里是占位值。
  # 若未来新增其他 system，这里给出明确失败而非难懂的哈希不匹配。
  unwrapped =
    assert lib.assertMsg (pkgsFlutter.stdenv.hostPlatform.system == "x86_64-linux")
      "BeeCount: 密闭 Flutter 数据（nix/flutter-versions/${flutterVersion}.json）只含 x86_64-linux 实测哈希；新增其他 system 需先重新生成数据（见 nix/flutter-versions/README.md）。";
    pkgsFlutter.flutterPackages.mkFlutter (
      flutterData
      // {
        inherit patches enginePatches;
      }
    );

  # 只保留本仓库实际需要的目标平台，避免下载 web/ios 等无关引擎产物。
  # android 供密封 SDK 直接 `flutter build apk`（配合 nix/android.nix 的 SDK/JDK）。
  # "linux" 不能当冗余项删掉：本 PR 自身的密封 analyze/test 用不到它（flutter_tester 来自
  # universal 产物），但 Linux 桌面目标需要它提供的 GTK embedder 与 AOT snapshotter
  # （libflutter_linux_gtk.so / gen_snapshot），Linux 桌面预览目标（nix/linux.nix，另有 PR）
  # 就是直接复用这份密封 SDK；删掉 "linux" 会让该目标无法构建。
  wrapped = pkgsFlutter.callPackage (flutterDir + "/wrapper.nix") {
    flutter = unwrapped;
    supportedTargetFlutterPlatforms = [
      "universal"
      "linux"
      "android"
    ];
    artifactHashes = flutterData.artifactHashes;
  };
in
{
  inherit
    unwrapped
    wrapped
    patches
    enginePatches
    ;
}

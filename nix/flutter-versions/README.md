# 密封 Flutter 版本数据

本目录存放**与 `.fvmrc` 精确对应**的 Flutter SDK 版本数据，供 `nix/flutter.nix` 通过
`pkgsFlutter.flutterPackages.mkFlutter` 构建密闭（hermetic）的 Flutter SDK。

- 文件名：`<版本>.json`，例如 `.fvmrc` 里 `"flutter": "3.27.3"` → `3.27.3.json`。
- 内容：与 nixpkgs `pkgs/development/compilers/flutter/versions/<x_y>/data.json` 同构，
  但只在目标平台 `x86_64-linux` 写入实测哈希；其余平台（`aarch64-linux`、
  `x86_64-darwin`、`aarch64-darwin`）均为占位值 `sha256-AAAA…=`，本仓库不会使用。

## 生成 / 更新

版本变更时（改 `.fvmrc` 后）：

```bash
nix/gen-flutter-version.sh <版本>   # 例如 nix/gen-flutter-version.sh 3.27.3
```

`nix/gen-flutter-version.sh` 只是入口，实际执行 `nix/gen_flutter_version.py`；流程（需联网）：

1. 从 `flake.lock` 解析 `nixpkgs-flutter`（`nixos-25.05`）的 rev，并取其 store path；
2. 从 Flutter 官方 `releases_linux.json` 取 Dart 版本，从 GitHub 取 engine revision；
3. 用 `nix store prefetch-file` 计算 Flutter SDK tarball 与 Dart SDK 的哈希；
4. 用固定输出派生（FOD）计算 `flutter_tools` 的 `pubspec.lock` 及其哈希；
5. 用 FOD 计算 `x86_64-linux` 的 `universal` / `linux` / `android` 引擎产物哈希；
6. 组装并写入 `nix/flutter-versions/<版本>.json`。

脚本不会修改、也不会提交任何 nixpkgs 内容。

生成后请提交该 JSON。flake 只读 `.fvmrc`，找不到对应 JSON 时会在评估阶段报错并提示本命令。

#!/usr/bin/env bash
# 生成 / 更新 nix/flutter-versions/<版本>.json（与 .fvmrc 精确一致的密封 Flutter 数据）。
#
# 用法：
#   nix/gen-flutter-version.sh 3.27.3
#
# 需要联网。首次会下载 Flutter 引擎产物以计算哈希，耗时较长。
# 生成后请把 nix/flutter-versions/<版本>.json 提交到仓库。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "${SCRIPT_DIR}/gen_flutter_version.py" "$@"

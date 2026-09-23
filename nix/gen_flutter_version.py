#!/usr/bin/env python3
"""为 nix/flutter-versions/<版本>.json 生成与 .fvmrc 精确对应的哈希数据。

由 nix/gen-flutter-version.sh 调用；也可直接运行：

    python3 nix/gen_flutter_version.py 3.27.3

流程（需要联网，属一次性操作）：
  1. 从 flake.lock 解析出 nixpkgs-flutter(nixos-25.05) 的 store path；
  2. 从 Flutter 官方发布索引取 dart 版本，从 GitHub 取 engine revision；
  3. 用 nix-prefetch-url 计算 flutter SDK tarball 与 Dart SDK 的哈希；
  4. 用固定输出派生（FOD）计算 flutter_tools 的 pubspec.lock 及其哈希；
  5. 用 FOD 计算 x86_64-linux 的 universal / linux 引擎产物哈希；
  6. 组装并写入 nix/flutter-versions/<版本>.json。

说明：本仓库只支持 x86_64-linux，因此非宿主平台的哈希写占位值（永不会被构建）。
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import tempfile
import time

SYSTEM = "x86_64-linux"
PLATFORMS = ["universal", "linux", "android"]
ARCHIVE_BASE = "https://storage.googleapis.com/flutter_infra_release/releases"
DART_BASE = "https://storage.googleapis.com/dart-archive/channels"
# 非宿主平台的占位哈希。必须是合法 SRI，否则新增 system 时只会得到难懂的解析错误。
FAKE_SRI = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="


def run(cmd: list[str], **kw) -> str:
    result = subprocess.run(cmd, capture_output=True, text=True, **kw)
    if result.returncode != 0:
        raise SystemExit(
            f"命令失败: {' '.join(cmd)}\nstdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )
    return result.stdout


def run_capture_err(cmd: list[str]) -> str:
    """运行会失败的 nix-build（fake hash），返回 stderr，用于抓取真实哈希。"""
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.stdout + result.stderr


def repo_root() -> str:
    return run(["git", "rev-parse", "--show-toplevel"]).strip()


def nixpkgs_flutter_path(root: str) -> str:
    lock = json.load(open(os.path.join(root, "flake.lock")))
    node = lock["nodes"]["nixpkgs-flutter"]["locked"]
    rev = node["rev"]
    meta = json.loads(
        run(["nix", "flake", "metadata", f"github:NixOS/nixpkgs/{rev}", "--json"])
    )
    return meta["path"]


def _retry(fn, attempts: int = 12, delay: float = 2.0):
    """重试网络相关操作（代理可能间歇性抖动）。"""
    last: Exception | None = None
    for _ in range(attempts):
        try:
            return fn()
        except SystemExit as exc:  # run() 失败时抛 SystemExit
            last = exc
            time.sleep(delay)
    assert last is not None
    raise last


def prefetch_file(url: str) -> str:
    out = json.loads(
        _retry(lambda: run(["nix", "store", "prefetch-file", "--json", url]))
    )
    return out["storePath"]


def prefetch_unpack_sri(url: str) -> str:
    # 用 nix 自带下载器（带重试），避免代理抖动导致的一次性失败。
    out = json.loads(
        _retry(
            lambda: run(["nix", "store", "prefetch-file", "--unpack", "--json", url])
        )
    )
    return out["hash"]


def run_for_hash(cmd: list[str], pattern: str, attempts: int = 8) -> str:
    """反复运行 FOD（fake hash），直到输出里出现目标哈希（容忍网络抖动）。"""
    out = ""
    for _ in range(attempts):
        out = run_capture_err(cmd)
        if re.search(pattern, out):
            return out
        time.sleep(3)
    raise SystemExit(f"未能在 {attempts} 次尝试内获得哈希:\n{out[-4000:]}")


def extract_hash(stderr: str, pattern: str) -> str:
    match = re.search(pattern, stderr)
    if not match:
        raise SystemExit(f"未能从输出中解析哈希:\n{stderr[-4000:]}")
    return match.group(1)


def gen_pubspec_lock(
    nfpath: str, version: str, dart_version: str, dart_hash_host: str, flutter_hash: str, tmp: str
) -> dict:
    expr = f"""
let
  pkgsFlutter = import {nfpath} {{ system = "{SYSTEM}"; }};
  lib = pkgsFlutter.lib;
  dartVersion = "{dart_version}";
  channel = "stable";
  dart = pkgsFlutter.dart.override {{
    version = dartVersion;
    sources = {{
      "${{dartVersion}}-x86_64-linux" = pkgsFlutter.fetchzip {{
        url = "{DART_BASE}/${{channel}}/release/${{dartVersion}}/sdk/dartsdk-linux-x64-release.zip";
        sha256 = "{dart_hash_host}";
      }};
      "${{dartVersion}}-aarch64-linux" = pkgsFlutter.fetchzip {{
        url = "{DART_BASE}/${{channel}}/release/${{dartVersion}}/sdk/dartsdk-linux-arm64-release.zip";
        sha256 = lib.fakeSha256;
      }};
      "${{dartVersion}}-x86_64-darwin" = pkgsFlutter.fetchzip {{
        url = "{DART_BASE}/${{channel}}/release/${{dartVersion}}/sdk/dartsdk-macos-x64-release.zip";
        sha256 = lib.fakeSha256;
      }};
      "${{dartVersion}}-aarch64-darwin" = pkgsFlutter.fetchzip {{
        url = "{DART_BASE}/${{channel}}/release/${{dartVersion}}/sdk/dartsdk-macos-arm64-release.zip";
        sha256 = lib.fakeSha256;
      }};
    }};
  }};
  flutterSrc = pkgsFlutter.fetchFromGitHub {{
    owner = "flutter"; repo = "flutter"; rev = "{version}";
    hash = "{flutter_hash}";
  }};
in
pkgsFlutter.stdenv.mkDerivation {{
  name = "beecount-pubspec-lock";
  src = flutterSrc;
  nativeBuildInputs = [ dart ];
  # 从呼叫者环境借用代理变量（fixed-output derivation 允许的不纯输入），
  # 避免把带凭证的 proxy URL 写进本档或 build log。
  impureEnvVars = lib.fetchers.proxyImpureEnvVars;
  outputHashAlgo = "sha256";
  outputHashMode = "recursive";
  outputHash = {_PUBSPEC_HASH[0]};
  buildPhase = ''
    cd ./packages/flutter_tools
    export HOME="$(mktemp -d)"
    dart --root-certs-file=${{pkgsFlutter.cacert}}/etc/ssl/certs/ca-bundle.crt pub get -v
  '';
  installPhase = ''
    cp -r ./pubspec.lock $out
  '';
}}
"""
    expr_path = os.path.join(tmp, "pubspec-lock.nix")
    with open(expr_path, "w") as f:
        f.write(expr)

    if not _PUBSPEC_RESOLVED[0]:
        out = run_for_hash(
            ["nix-build", "--no-out-link", "--keep-going", expr_path],
            r"got:\s+(sha256-[A-Za-z0-9+/=]+)",
        )
        got = extract_hash(out, r"got:\s+(sha256-[A-Za-z0-9+/=]+)")
        _PUBSPEC_HASH[0] = f'"{got}"'
        _PUBSPEC_RESOLVED[0] = True
        return gen_pubspec_lock(
            nfpath, version, dart_version, dart_hash_host, flutter_hash, tmp
        )

    out_path = run(["nix-build", "--no-out-link", expr_path]).strip().splitlines()[-1]
    lock_json = run(["nix", "run", "nixpkgs#yq-go", "--", "-o=json", ".", out_path])
    return json.loads(lock_json)


def gen_artifact_hashes(nfpath: str, compact: str, partial: dict, tmp: str) -> dict:
    partial_path = os.path.join(tmp, "partial.json")
    json.dump(partial, open(partial_path, "w"), indent=2)

    expr = f"""
let
  flutterDir = {nfpath}/pkgs/development/compilers/flutter;
  pkgsFlutter = import {nfpath} {{ system = "{SYSTEM}"; }};
  lib = pkgsFlutter.lib;
  versionDir = "${{flutterDir}}/versions/{compact}";
  patchesFrom =
    dir:
    if builtins.pathExists dir then
      map (f: dir + "/${{f}}") (builtins.attrNames (builtins.readDir dir))
    else
      [ ];
  patches = patchesFrom (flutterDir + "/patches") ++ patchesFrom (versionDir + "/patches");
  enginePatches =
    patchesFrom (flutterDir + "/engine/patches") ++ patchesFrom (versionDir + "/engine/patches");
  data = builtins.fromJSON (builtins.readFile "{partial_path}");
  unwrapped = pkgsFlutter.flutterPackages.mkFlutter (data // {{ inherit patches enginePatches; }});
  wrapped = pkgsFlutter.callPackage (flutterDir + "/wrapper.nix") {{
    flutter = unwrapped;
    artifactHashes = {{ }};
  }};
  mk = platform:
    pkgsFlutter.callPackage (flutterDir + "/artifacts/fetch-artifacts.nix") {{
      flutter = wrapped;
      flutterPlatform = platform;
      systemPlatform = "{SYSTEM}";
      hash = lib.fakeSha256;
    }};
in
{{ universal = mk "universal"; linux = mk "linux"; android = mk "android"; }}
"""
    expr_path = os.path.join(tmp, "artifacts.nix")
    with open(expr_path, "w") as f:
        f.write(expr)

    patterns = {
        platform: rf"flutter-artifacts-{platform}-{SYSTEM}\.drv':\n\s+specified: .*\n\s+got:\s+(sha256-[A-Za-z0-9+/=]+)"
        for platform in PLATFORMS
    }

    out = ""
    for _ in range(8):
        out = run_capture_err(["nix-build", "--no-out-link", "--keep-going", expr_path])
        if all(re.search(p, out) for p in patterns.values()):
            break
        time.sleep(3)

    return {platform: extract_hash(out, p) for platform, p in patterns.items()}


_PUBSPEC_HASH: list[str] = [f'"{FAKE_SRI}"']
_PUBSPEC_RESOLVED: list[bool] = [False]


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("用法: gen-flutter-version.sh <版本，例如 3.27.3>")
    version = sys.argv[1]
    if not re.fullmatch(r"\d+\.\d+\.\d+", version):
        raise SystemExit(f"版本格式不正确: {version}")
    compact = "_".join(version.split(".")[:2])

    root = repo_root()
    os.chdir(root)
    nfpath = nixpkgs_flutter_path(root)

    # 发布索引 & engine revision
    releases = json.load(open(prefetch_file(f"{ARCHIVE_BASE}/releases_linux.json")))
    release = next((r for r in releases["releases"] if r["version"] == version), None)
    if release is None:
        raise SystemExit(f"Flutter 发布索引中找不到版本 {version}")
    dart_version = release["dart_sdk_version"]
    engine_version = open(
        prefetch_file(f"https://raw.githubusercontent.com/flutter/flutter/{version}/bin/internal/engine.version")
    ).read().strip()

    print(f"Flutter {version} / Dart {dart_version} / engine {engine_version}")

    flutter_hash = prefetch_unpack_sri(
        f"https://github.com/flutter/flutter/archive/{version}.tar.gz"
    )
    dart_hash_host = prefetch_unpack_sri(
        f"{DART_BASE}/stable/release/{dart_version}/sdk/dartsdk-linux-x64-release.zip"
    )
    with tempfile.TemporaryDirectory(prefix="beecount-flutter-") as tmp:
        pubspec_lock = gen_pubspec_lock(
            nfpath, version, dart_version, dart_hash_host, flutter_hash, tmp
        )

        partial = {
            "version": version,
            "engineVersion": engine_version,
            "engineSwiftShaderHash": "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
            "engineSwiftShaderRev": "0" * 40,
            "channel": "stable",
            "engineHashes": {},
            "dartVersion": dart_version,
            "dartHash": {
                "x86_64-linux": dart_hash_host,
                "aarch64-linux": FAKE_SRI,
                "x86_64-darwin": FAKE_SRI,
                "aarch64-darwin": FAKE_SRI,
            },
            "flutterHash": flutter_hash,
            "artifactHashes": {},
            "pubspecLock": pubspec_lock,
        }
        artifact_hashes = gen_artifact_hashes(nfpath, compact, partial, tmp)

    data = dict(partial)
    data["artifactHashes"] = {
        p: {"x86_64-linux": h} for p, h in artifact_hashes.items()
    }

    out_dir = os.path.join(root, "nix", "flutter-versions")
    os.makedirs(out_dir, exist_ok=True)
    out_file = os.path.join(out_dir, f"{version}.json")
    with open(out_file, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    print(f"已写入 {out_file}")


if __name__ == "__main__":
    main()

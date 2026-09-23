# 密封 Android 用的 Flutter 包装器（`flutter-android`）。
#
# 密封 SDK 位于只读的 Nix store，而 Gradle 的 composite build
# （`includeBuild("$flutter.sdk/packages/flutter_tools/gradle")`）需要在
# included build 目录下建立 `.gradle/`，只读会失败（且 Gradle 会静默 exit 1）。
#
# 因此首次调用时在 `$XDG_CACHE_HOME/beecount/flutter-root-<版本>` 建立一层
# 可写 overlay：目录为实体、文件指回 store，只把 packages/flutter_tools/gradle
# 复制成可写副本；随后把 FLUTTER_ROOT 指向 overlay 再执行密封 flutter。
# 这样 devShell 与 `nix run .#flutter-android` 都能直接用密封 SDK 做 Android 建置。
{
  pkgs,
  flutterVersion,
  hermeticFlutter,
}:
pkgs.writeShellApplication {
  name = "flutter";
  runtimeInputs = [ pkgs.coreutils ];
  text = ''
    sealed="${hermeticFlutter.wrapped}"
    overlay="''${XDG_CACHE_HOME:-$HOME/.cache}/beecount/flutter-root-${flutterVersion}"

    if [ ! -e "$overlay/.sealed-sdk" ] || [ "$(cat "$overlay/.sealed-sdk" 2>/dev/null)" != "$sealed" ]; then
      chmod -R u+w "$overlay" 2>/dev/null || true
      rm -rf "$overlay"
      mkdir -p "$overlay/packages/flutter_tools"

      for e in "$sealed"/* "$sealed"/.[!.]*; do
        if [ ! -e "$e" ]; then continue; fi
        b="$(basename "$e")"
        if [ "$b" = packages ]; then continue; fi
        ln -sfn "$e" "$overlay/$b"
      done

      for e in "$sealed"/packages/*; do
        b="$(basename "$e")"
        if [ "$b" = flutter_tools ]; then continue; fi
        ln -sfn "$e" "$overlay/packages/$b"
      done

      for e in "$sealed"/packages/flutter_tools/* "$sealed"/packages/flutter_tools/.[!.]*; do
        if [ ! -e "$e" ]; then continue; fi
        b="$(basename "$e")"
        if [ "$b" = gradle ]; then continue; fi
        ln -sfn "$e" "$overlay/packages/flutter_tools/$b"
      done

      cp -r --no-preserve=mode,ownership "$sealed/packages/flutter_tools/gradle" \
        "$overlay/packages/flutter_tools/gradle"
      printf '%s' "$sealed" > "$overlay/.sealed-sdk"
    fi

    export FLUTTER_ROOT="$overlay"
    exec "$sealed/bin/flutter" "$@"
  '';
}

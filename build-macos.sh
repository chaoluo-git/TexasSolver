#!/bin/bash
set -euo pipefail

# Use Homebrew by default, or provide QT_DIR and LIBOMP_PREFIX explicitly.
# BUILD_DIR and BUILD_JOBS can override the build location and parallelism.
repo_root="$(cd -- "$(dirname -- "$0")" && pwd)"
app_name=TexasSolverGui
build_dir="${BUILD_DIR:-$repo_root/build-mac}"
qt_dir="${QT_DIR:-${QT_ROOT_DIR:-$(brew --prefix qt@5 2>/dev/null || true)}}"
export LIBOMP_PREFIX="${LIBOMP_PREFIX:-$(brew --prefix libomp 2>/dev/null || true)}"
brew_prefix="$(brew --prefix 2>/dev/null || true)"
arch="$(uname -m)"

if [[ -z "$qt_dir" || ! -x "$qt_dir/bin/qmake" || ! -x "$qt_dir/bin/macdeployqt" ]]; then
    echo "Install Qt 5 with 'brew install qt@5' or set QT_DIR to a Qt 5 installation." >&2
    exit 1
fi
if [[ -z "$LIBOMP_PREFIX" || ! -f "$LIBOMP_PREFIX/include/omp.h" || ! -f "$LIBOMP_PREFIX/lib/libomp.dylib" ]]; then
    echo "Install libomp with 'brew install libomp' or set LIBOMP_PREFIX." >&2
    exit 1
fi

mkdir -p "$build_dir"
build_dir="$(cd -- "$build_dir" && pwd)"
cd "$build_dir"
"$qt_dir/bin/qmake" "$repo_root/TexasSolverGui.pro" CONFIG+=release CONFIG+=sdk_no_version_check
make -j"${BUILD_JOBS:-$(sysctl -n hw.ncpu)}"

app="$build_dir/$app_name.app"
frameworks="$app/Contents/Frameworks"
"$qt_dir/bin/macdeployqt" "$app" -always-overwrite
test -f "$app/Contents/PlugIns/platforms/libqcocoa.dylib"

mach_o_files() {
    find "$app/Contents" -type f \( -name '*.dylib' -o -perm -u+x \) \
        -exec sh -c 'file -b "$1" | grep -q Mach-O' _ {} \; -print0
}

dependencies() {
    otool -arch "$arch" -L "$1" | awk 'NR > 1 {
        sub(/^[[:space:]]+/, "")
        sub(/ \(compatibility version.*/, "")
        print
    }'
}

# macdeployqt may leave transitive Homebrew dylibs (such as libbrotlicommon)
# unresolved. Copy each missing dylib once and rewrite its consumers to the app.
added_library=1
while [[ "$added_library" == 1 ]]; do
    added_library=0
    while IFS= read -r -d '' binary; do
        install_id="$(otool -arch "$arch" -D "$binary" | sed -n '2p')"
        linked="$(dependencies "$binary")"
        while IFS= read -r dependency; do
            [[ -z "$dependency" || "$dependency" == "$install_id" ]] && continue
            case "$dependency" in
                /usr/lib/*|/System/Library/*) continue ;;
                @executable_path/../Frameworks/*)
                    relative="${dependency#@executable_path/../Frameworks/}" ;;
                @loader_path/*)
                    if [[ -e "${binary%/*}/${dependency#@loader_path/}" ]]; then
                        continue
                    fi
                    relative="${dependency##*/}" ;;
                @rpath/*) relative="${dependency#@rpath/}" ;;
                *.dylib) relative="${dependency##*/}" ;;
                *)
                    echo "Unbundled dependency $dependency required by $binary" >&2
                    exit 1 ;;
            esac

            if [[ ! -e "$frameworks/$relative" ]]; then
                source_path="$dependency"
                if [[ "$relative" == libomp.dylib ]]; then
                    source_path="$LIBOMP_PREFIX/lib/libomp.dylib"
                elif [[ ! -f "$source_path" && -n "$brew_prefix" && "$relative" == *.dylib && "$relative" != */* ]]; then
                    source_path="$(find -L "$brew_prefix/lib" "$brew_prefix/opt" -name "$relative" -print -quit 2>/dev/null || true)"
                fi
                if [[ "$relative" == */* || ! -f "$source_path" ]]; then
                    echo "Cannot bundle dependency $dependency required by $binary" >&2
                    exit 1
                fi
                cp -L "$source_path" "$frameworks/$relative"
                chmod u+w "$frameworks/$relative"
                install_name_tool -id "@executable_path/../Frameworks/$relative" "$frameworks/$relative"
                added_library=1
            fi

            bundled_path="@executable_path/../Frameworks/$relative"
            if [[ "$dependency" != "$bundled_path" ]]; then
                chmod u+w "$binary"
                install_name_tool -change "$dependency" "$bundled_path" "$binary"
            fi
        done <<< "$linked"
        lipo -verify_arch "$arch" "$binary"
    done < <(mach_o_files)
done

test -f "$frameworks/libomp.dylib"
codesign --force --deep --sign - "$app"
codesign --verify --deep --strict "$app"

stage_dir="$(mktemp -d "$build_dir/.dmg-stage.XXXXXX")"
trap 'rm -rf -- "$stage_dir"' EXIT
mkdir "$stage_dir/contents"
ditto "$app" "$stage_dir/contents/$app_name.app"
cp "$repo_root/LICENSE" "$stage_dir/contents/LICENSE"
ln -s /Applications "$stage_dir/contents/Applications"
hdiutil create -volname "$app_name" -srcfolder "$stage_dir/contents" -format UDZO "$stage_dir/$app_name.dmg"
hdiutil verify "$stage_dir/$app_name.dmg"
mv -f "$stage_dir/$app_name.dmg" "$build_dir/$app_name.dmg"

echo "Built: $app"
echo "Built: $build_dir/$app_name.dmg"

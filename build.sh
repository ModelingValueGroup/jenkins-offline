#!/usr/bin/env bash
set -ue

################################################################
mavenRepoDir="$1"; shift
      jdkDir="$1"; shift
  minVersion="$1"; shift
       token="$1"; shift
     publish="$1"; shift
################################################################
rm -rf tools
git clone 'https://github.com/ModelingValueGroup/tools.git'
. tools/tools.sh
################################################################

export PLUGIN_TREE=plugin-tree
export    ADD_TREE=add-tree
export   PREV_TREE=prev-tree
export  MAVEN_OPTS="-Dmaven.repo.local=$mavenRepoDir"
echo

echo "======== setup submodules"
git submodule init
git submodule update
echo

echo "======== build juseppe"
(   cd juseppe
    (   git checkout master
        git clean -fdx
        git pull
    ) > git.log
    ./build.sh
)
echo

echo "======== build update-center2"
(   cd update-center2
    (   git checkout master
        git clean -fdx
        git pull
    ) > git.log
    ./build.sh
)
echo

echo "======== making download dir with plugins from dentral repos"
java \
    -Dmaven.repo.local=$mavenRepoDir \
    -cp update-center2/target/update-center2-*-bin*/update-center2-*.jar \
    org.jvnet.hudson.update_center.MainOnlyDownload \
    -version  "$minVersion" \
    -download "$PLUGIN_TREE"
echo

echo "======== get previous release to compare against"
downloadLatestRelease "$token" $PREV_TREE
pushd "$PREV_TREE"
7z x *.7z.001
rm   *.7z.0*
popd
mkdir "$ADD_TREE"
(cd "$PLUGIN_TREE"; find . -type f) \
    | while read f; do
        if [[ -f "$PREV_TREE/$f" ]]; then
            echo ">>> prev and now: $f"
        else
            echo ">>> NEW         : $f"
            mkdir "$(dirname "$ADD_TREE/$f")"
            ln "$PLUGIN_TREE/$f" "$ADD_TREE/$f"
        fi
    done
#rm -rf "$PREV_TREE"
echo

echo "======== copy juseppe jar into downloads"
cp juseppe/juseppe-cli/target/juseppe.jar "$PLUGIN_TREE"
echo

echo "======== zipping it all"
7z -mx0 -v500m a "$PLUGIN_TREE.7z" "$PLUGIN_TREE" > 7z.log
7z -mx0 -v500m a "$ADD_TREE.7z"    "$ADD_TREE"    > 7z.log
rm -rf "$PLUGIN_TREE"
rm -rf "$ADD_TREE"
echo

if [[ $publish == true ]]; then
    echo "======== publish to GitHub"
    publishOnGitHub "$(date "+State-%Y-%m%d-%H%M")" "$token" false "$PLUGIN_TREE.7z"* "$ADD_TREE.7z"*
    rm "$PLUGIN_TREE.7z"*
    rm "$ADD_TREE.7z"*
    echo
fi
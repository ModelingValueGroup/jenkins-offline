#!/usr/bin/env bash
set -ue

################################################################
mavenRepoDir="$1"; shift
      jdkDir="$1"; shift
  minVersion="$1"; shift
       token="$1"; shift
################################################################
git clone 'https://github.com/ModelingValueGroup/tools.git'
. tools/tools.sh
################################################################

export DOWNLOAD_DIR=plugin-tree
export   MAVEN_OPTS="-Dmaven.repo.local=$mavenRepoDir"
echo

echo "======== trial publish to GitHub"
echo aap > aap
7z a aap.7z aap
set -x
publishOnGitHub "latest" "$token" false aap aap.7z
echo
[ ] || exit

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

echo "======== making download dir with plugins"
java \
    -Dmaven.repo.local=$mavenRepoDir \
    -cp update-center2/target/update-center2-*-bin*/update-center2-*.jar \
    org.jvnet.hudson.update_center.MainOnlyDownload \
    -version  "$minVersion" \
    -download "$DOWNLOAD_DIR"
cp juseppe/juseppe-cli/target/juseppe.jar "$DOWNLOAD_DIR"
echo

echo "======== zipping it all"
7z a "$DOWNLOAD_DIR.7z" "$DOWNLOAD_DIR" > 7z.log
rm -rf "$DOWNLOAD_DIR"
echo

echo "======== publish to GitHub"
publishOnGitHub "latest" "$token" false "$DOWNLOAD_DIR.7z"
echo

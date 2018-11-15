#!/usr/bin/env bash
set -ue

################################################################
mavenRepoDir="$1"; shift
      jdkDir="$1"; shift
  minVersion="$1"; shift
       token="$1"; shift
################################################################
rm -rf tools
git clone 'https://github.com/ModelingValueGroup/tools.git'
. tools/tools.sh
################################################################

export DOWNLOAD_DIR=plugin-tree
export   MAVEN_OPTS="-Dmaven.repo.local=$mavenRepoDir"
echo

echo "======== trial publish to GitHub"
set -x
publishOnGitHub "SNAPSHOT" "$token" false /tmp/bigfile.7z.*
[ xxx ] && exit 0

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
7z -v2g a "$DOWNLOAD_DIR.7z" "$DOWNLOAD_DIR" > 7z.log
rm -rf "$DOWNLOAD_DIR"
echo

echo "======== publish to GitHub"
publishOnGitHub "SNAPSHOT" "$token" false "$DOWNLOAD_DIR.7z"*
rm "$DOWNLOAD_DIR.7z"*
echo

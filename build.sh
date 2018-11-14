#!/usr/bin/env bash
set -ue

mavenRepoDir="$1"; shift
      jdkDir="$1"; shift

 MIN_VERSION=2.151
DOWNLOAD_DIR=tmp-plugins

export MAVEN_OPTS="-Dmaven.repo.local=$mavenRepoDir"
echo

echo "======== setup submodules"
git submodule init
git submodule update
echo

echo "======== build juseppe"
(   cd juseppe
    git checkout master
    git clean -fdx
    git pull
     ./build.sh
)
echo

echo "======== build update-center2"
(   cd update-center2
    git checkout master
    git clean -fdx
    git pull
    ./build.sh
)
echo

echo "======== making download dir with plugins"
java \
    -cp update-center2/target/update-center2-*-bin*/update-center2-*.jar \
    org.jvnet.hudson.update_center.MainOnlyDownload \
    -version  "$MIN_VERSION" \
    -download "$DOWNLOAD_DIR"

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

export DOWNLOAD_DIR=plugin-tree
export   MAVEN_OPTS="-Dmaven.repo.local=$mavenRepoDir"
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
    -download "$DOWNLOAD_DIR"
echo

echo "======== get previous release to compare against"
downloadLatestRelease "$token" prevRelease
pushd prevRelease
7z e *.001
popd
echo
true && exit 7

echo "======== copy juseppe jar into downloads"
cp juseppe/juseppe-cli/target/juseppe.jar "$DOWNLOAD_DIR"
echo

echo "======== zipping it all"
7z -mx0 -v500m a "$DOWNLOAD_DIR.7z" "$DOWNLOAD_DIR" > 7z.log
rm -rf "$DOWNLOAD_DIR"
echo

if [[ $publish == true ]]; then
    echo "======== publish to GitHub"
    publishOnGitHub "$(date "+State-%Y-%m%d-%H%M")" "$token" false "$DOWNLOAD_DIR.7z"*
    rm "$DOWNLOAD_DIR.7z"*
    echo
fi
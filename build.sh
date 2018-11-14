#!/usr/bin/env bash
set -ue

mavenRepoDir="$1"; shift
      jdkDir="$1"; shift


export MAVEN_OPTS="-Dmaven.repo.local=$mavenRepoDir"
echo

echo "======== setup submodules"
git submodule init
git submodule update
echo

echo "======== build juseppe"
(   cd juseppe
    git pull
     ./build.sh
)
echo

echo "======== build update-center2"
(   cd update-center2
    git pull
    ./build.sh
)
echo


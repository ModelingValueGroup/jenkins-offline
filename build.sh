#!/usr/bin/env bash

echo

git submodule init
git submodule update
echo

(cd juseppe       ; git pull)
(cd update-center2; git pull)
echo

(cd juseppe       ; ./build.sh)
(cd update-center2; ./build.sh)
echo


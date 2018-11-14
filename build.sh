#!/usr/bin/env bash

echo
git submodule init
git submodule update
(cd juseppe       ; git pull)
(cd update-center2; git pull)
echo

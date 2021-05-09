#! /usr/bin/env bash

base=/home/snapCloud/snap/

pushd $base/snap/;
echo "Updating Main Snap! Release"
echo
git fetch origin
snap_release=$(git describe --tags $(git rev-list --tags --max-count=1))
echo "Checking out Snap! ${snap_release}"
git checkout $snap_release
popd;
echo
echo


pushd $base/snap-versions/dev;
echo "Updating DEVELOPMENT Snap!"
echo
git fetch origin
snap_release="origin/master"
echo "Checking out Snap! $snap_release"
git checkout $snap_release
popd;
echo
echo

snap_release="v6.0.0" # must be exactly a git tag.
pushd $base/snap-versions/previous;
echo "Updating Previous Snap!: $snap_release"
echo
git fetch origin
echo "Checking out $snap_release"
git checkout $snap_release
popd;
echo
echo

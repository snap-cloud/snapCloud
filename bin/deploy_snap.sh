#! /usr/bin/env bash

pushd /home/snapCloud/snap/

echo "Updating Main Snap! Release"
echo
pushd snap
git fetch origin
snap_release=$(git describe --tags $(git rev-list --tags --max-count=1))
echo "Checking out Snap! ${snap_release}"
git checkout $snap_release
popd

echo "Updating DEVELOPMENT Snap!"
echo
pushd snap-versions/dev
git fetch origin
snap_release="origin/master"
echo "Checking out Snap! $snap_release"
git checkout origin/master
popd;

snap_release="v6.0.0" # must be exactly a git tag.
echo "Updating Previous Snap!: $snap_release"
echo
pushd snap-versions/previous
git fetch origin
echo "Checking out $snap_release"
git checkout $snap_release
popd;

popd;

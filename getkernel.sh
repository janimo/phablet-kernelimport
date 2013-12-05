#!/bin/bash
# Pull a given prebuilt Ubuntu Touch kernel into a git repositories to be used by repo manifests

if [ $# -ne 2 ];then
	echo Usage $0 DEVICE SERIES
	exit
fi

cd $(dirname $0)

DEVICE=$1
TARGET_KERNEL_UBUNTU_SERIES=$2

TARGET_KERNEL_UBUNTU_META=linux-image-$DEVICE

PULL_LP_BIN=./pull-lp-bin.py


# Download and unpack the kernel binary package from Launchpad


TARGET_OUT_UBUNTU_KERNEL=tmp-$TARGET_KERNEL_UBUNTU_META
#rm -Rf $TARGET_OUT_UBUNTU_KERNEL
mkdir -p $TARGET_OUT_UBUNTU_KERNEL
$PULL_LP_BIN $TARGET_KERNEL_UBUNTU_META -o $TARGET_OUT_UBUNTU_KERNEL $TARGET_KERNEL_UBUNTU_SERIES
kernel_image=`dpkg-deb -f $TARGET_OUT_UBUNTU_KERNEL/"$TARGET_KERNEL_UBUNTU_META"_*.deb Depends | grep -o -e 'linux-image-[^ ,]*'`
if [ ! -n "$kernel_image" ]; then
	echo Could not find image
	exit
fi

$PULL_LP_BIN $kernel_image -o $TARGET_OUT_UBUNTU_KERNEL $TARGET_KERNEL_UBUNTU_SERIES
dpkg-deb -x $TARGET_OUT_UBUNTU_KERNEL/linux-image-[0-9]*.deb $TARGET_OUT_UBUNTU_KERNEL
kernel_version=${kernel_image#linux-image-}


# Place vmlinuz and the modules under a local git repo/workdir, skipping if no change has been made since last check

LOCAL_REPOS_PATH=git
PUBLIC_REPOS_PATH=/srv/phablet.ubuntu.com/git/ubuntu/kernels
REPO_NAME=ubuntu_prebuilt_kernel_$DEVICE

GITDIR=$LOCAL_REPOS_PATH/$REPO_NAME
PUBGITDIR=$PUBLIC_REPOS_PATH/$REPO_NAME.git

mkdir -p $GITDIR

cp $TARGET_OUT_UBUNTU_KERNEL/boot/vmlinuz-$kernel_version $GITDIR/kernel
cp -a $TARGET_OUT_UBUNTU_KERNEL/lib $GITDIR

cd $GITDIR

git init

git add .

git commit -s -m "Add $kernel_image"

#Create and initialize repo if first run
mkdir -p $PUBGITDIR
GIT_DIR=$PUBGITDIR git init --bare --shared=group

#Push from local to public repo
git push $PUBGITDIR master

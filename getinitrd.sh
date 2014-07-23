#!/bin/bash
# Pull a given prebuilt Ubuntu Touch kernel into a git repositories to be used by repo manifests

if [ $# -lt 1 ];then
	echo "Usage $0 SERIES [REPOS_DIR]"
	exit
fi

cd $(dirname $0)

UBUNTU_SERIES=$1

PACKAGE_NAME=ubuntu-touch-generic-initrd

PULL_LP_BIN=./pull-lp-bin.py

# Download and unpack the kernel binary package from Launchpad

OUT_DIR=tmp-initrd

mkdir -p $OUT_DIR
$PULL_LP_BIN $PACKAGE_NAME -o $OUT_DIR $UBUNTU_SERIES
dpkg-deb -x $OUT_DIR/$PACKAGE_NAME*.deb $OUT_DIR
a=`ls $OUT_DIR/*deb`
initrd_version=${a#*_}
initrd_version=${initrd_version%_*}

# Place the initramfs binary under a local git repo/workdir, skipping if no change has been made since last check

LOCAL_REPOS_PATH=git
PUBLIC_REPOS_PATH=${2:-/srv/phablet.ubuntu.com/git/ubuntu/initrd}
REPO_NAME=ubuntu_prebuilt_initrd

GITDIR=$LOCAL_REPOS_PATH/$REPO_NAME
PUBGITDIR=$PUBLIC_REPOS_PATH/$REPO_NAME.git

mkdir -p $GITDIR

cp $OUT_DIR/usr/lib/ubuntu-touch-generic-initrd/initrd.img-touch $GITDIR/

cd $GITDIR

git init

git add .

git commit -s -m "Add $PACKAGE_NAME version $initrd_version"

#Create and initialize repo if first run
mkdir -p $PUBGITDIR
GIT_DIR=$PUBGITDIR git init --bare --shared=group

#Push from local to public repo
git push $PUBGITDIR master

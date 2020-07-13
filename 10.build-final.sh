#!/bin/bash

SITES="clusters"
PREFIX="common"

if [[ ! ( ( "`hostname -f`" == "deb8.ncbr.muni.cz" ) || ( "`hostname -f`" == *"salomon"* ) )  ]]; then
    echo "unsupported build machine!"
    exit 1
fi

set -o pipefail

# ------------------------------------
if [ -z "$AMS_ROOT" ]; then
   echo "ERROR: This installation script works only in the Infinity environment!"
   exit 1
fi

# ------------------------------------------------------------------------------
module add cmake git intelcdk

# determine number of available CPUs if not specified
if [ -z "$N" ]; then
    N=1
    type nproc &> /dev/null
    if type nproc &> /dev/null; then
        N=`nproc --all`
    fi
    if [ "$N" -gt 4 ]; then
        N=4
    fi
fi

# ------------------------------------------------------------------------------
# update revision number
_PWD=$PWD
if ! [ -d src/projects/ffdevel/1.0 ]; then
    echo "src/projects/ffdevel/1.0 - not found"
    exit 1
fi

cd src/projects/ffdevel/1.0
./UpdateGitVersion activate
if [ $? -ne 0 ]; then echo "UpdateGitVersion failed"; exit 1; fi
VERS="3.`git rev-list --count HEAD`.`git rev-parse --short HEAD`"
if [ $? -ne 0 ]; then exit 1; fi
cd $_PWD

# names ------------------------------
NAME="ffdevel"
ARCH=`uname -m`
MODE="node" 
echo "Build: $NAME:$VERS:$ARCH:$MODE"
echo ""

echo ">>> Number of CPUs for building: $N"
echo ""

# build and install software ---------
cmake -DCMAKE_INSTALL_PREFIX="$SOFTREPO/$PREFIX/$NAME/$VERS/$ARCH/$MODE" .
if [ $? -ne 0 ]; then exit 1; fi

make -j "$N" install
if [ $? -ne 0 ]; then exit 1; fi

# prepare build file -----------------
SOFTBLDS="$AMS_ROOT/etc/map/builds/$PREFIX"
VERIDX=`ams-map-manip newverindex $NAME:$VERS:$ARCH:$MODE`

cat > $SOFTBLDS/$NAME:$VERS:$ARCH:$MODE.bld << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!-- Advanced Module System (AMS) build file -->
<build name="$NAME" ver="$VERS" arch="$ARCH" mode="$MODE" verindx="$VERIDX">
    <setup>
        <variable name="AMS_PACKAGE_DIR" value="$PREFIX/$NAME/$VERS/$ARCH/$MODE" operation="set" priority="modaction"/>
        <variable name="PATH" value="\$SOFTREPO/$PREFIX/$NAME/$VERS/$ARCH/$MODE/bin" operation="prepend"/>
    </setup>
</build>
EOF
if [ $? -ne 0 ]; then exit 1; fi

# deb8
cp /usr/lib/x86_64-linux-gnu/libboost_serialization.so.1.55.0 $SOFTREPO/$PREFIX/$NAME/$VERS/$ARCH/$MODE/lib
cp /usr/lib/x86_64-linux-gnu/libboost_filesystem.so.1.55.0 $SOFTREPO/$PREFIX/$NAME/$VERS/$ARCH/$MODE/lib
cp /usr/lib/x86_64-linux-gnu/libboost_system.so.1.55.0 $SOFTREPO/$PREFIX/$NAME/$VERS/$ARCH/$MODE/lib

echo ""
echo "Adding builds ..."
ams-map-manip addbuilds $SITES $NAME:$VERS:$ARCH:$MODE >> ams.log 2>&1
if [ $? -ne 0 ]; then echo ">>> ERROR: see ams.log"; exit 1; fi

echo "Distribute builds ..."
ams-map-manip distribute >> ams.log 2>&1
if [ $? -ne 0 ]; then echo ">>> ERROR: see ams.log"; exit 1; fi

echo "Rebuilding cache ..."
ams-cache rebuildall >> ams.log 2>&1
if [ $? -ne 0 ]; then echo ">>> ERROR: see ams.log"; exit 1; fi

echo "Log file: ams.log"
echo ""


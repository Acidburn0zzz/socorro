#!/bin/bash
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# Build script for building Breakpad
# Generally run in Taskcluster, but split out to a separate script
# so it can be run for local builds if necessary without assuming
# the Taskcluster environment.

# any failures in this script should cause the build to fail
set -v -e -x

export MAKEFLAGS=-j$(getconf _NPROCESSORS_ONLN)

git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH=`pwd`/depot_tools:$PATH

# Checkout and build Breakpad
echo "PREFIX: ${PREFIX:=`pwd`/build/breakpad}"
mkdir breakpad
cd breakpad
fetch breakpad
cd src
mkdir -p ${PREFIX}
rsync -a --exclude="*.git" ./src ${PREFIX}/
./configure --prefix=${PREFIX}
make install
if test -z "${SKIP_CHECK}"; then
  #FIXME: get this working again
  #make check
  true
fi
git rev-parse master > ${PREFIX}/revision.txt
cd ../..

cp breakpad/src/src/third_party/libdisasm/libdisasm.a ${PREFIX}/lib/

# Optionally package everything up
if test -z "${SKIP_TAR}"; then
  tar -C ${PREFIX}/.. --mode 755 --owner 0 --group 0 -zcf breakpad.tar.gz `basename ${PREFIX}`
fi

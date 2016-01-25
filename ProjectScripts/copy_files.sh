#!/bin/bash -eu
#
# Copyright 2015 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
################################################################################
#

#!/bin/bash
#
# This script copies the test data suite to an application-specific
# location.
#
# ==== Usage ====
#
#   $ ./copy_files.sh [destination]
#
# The optional destinaiton is the directory that files will be copied
# to. When it is not specified, the resource directory of an app's
# main bundle is used, which is always a reasonable default for build
# target types that create a bundle.

if [[ $# -ge 1 ]]; then
    destination="$1"
else
    destination="${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
fi

function install_files() {
    local source=$1
    local target=$2
    mkdir -p "$target"
    # Don't drop "/" after $source. rsync changes its behavior based on it.
    rsync -a --include="*/" --include="*.svg" --include="*.png" --exclude="*" "${source}/" "$target"
}

install_files \
    "${SRCROOT}/TestData" \
    "${destination}/TestData"

install_files \
    "${SRCROOT}/AcceptanceTest/Golden" \
    "${destination}/Golden"

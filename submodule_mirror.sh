#!/usr/bin/env bash

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#

if [[ ! -e ./.git ]]; then
    exit 0
fi

set +e

exec_submodule_mirror() {
    git submodule init
    # git config --list | grep submodule.*url= | sed -e 's#^\(.*url\)=https://github.com/\(.*\)$#git config \1 ssh://git@gitmirror.cixcomputing.com/github_mirror/\2##g' | while read c; do $c; done
    git config --list | grep submodule.*url= | grep 'github.com' | sed -e 's#^\(.*url\)=https://github.com/\(.*\)$#git config \1 ssh://git@gitmirror.cixcomputing.com/github_mirror/\2##g' | while read c; do $c; done
#    git config --list
}

exec_submodule_mirror
git submodule update --init
if [ $? -ne 0 ]; then
    exec_submodule_mirror
    set -e
    git submodule update --init
else
    set -e
fi

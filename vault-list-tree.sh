#!/bin/bash -e

# MIT License
# 
# Copyright (c) 2018 Xu Wang
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# List all kv path recursively from a given path
# Usage:
#   $0 <path>

export VAULT_ADDR=${VAULT_ADDR:-http://127.0.0.1:8200}

function get_children() {
    if children=$( $vault_list -format=json $1 2>/dev/null)
    then
        echo $children | jq -r '.[]'
    fi
}

function list() {
    echo $1
    for child in $(get_children $1)
    do
        list "${1}${child}"
    done
}

function abort() {
    echo "$1"
    echo && echo "Usage: $0 <path>" && echo
    exit 1
}

######
# Main
######

if [[ -z "$1" ]] || [[ "$1" =~ ^- ]]
then
    abort ""
else
    root=$1
    root=${root%/}  # Remove trailing slash if any. Will add it back later
fi 

if ! msg=$(vault status 2>&1)
then
    abort "$msg."
fi

# For kv2 backend only
vault_list="vault kv list"

if msg=$($vault_list $root 2>&1)
then
    list $root/
else
    abort "Error: $msg."
fi

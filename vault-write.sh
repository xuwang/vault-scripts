#!/bin/bash

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
# Usage:
#   vault-write <path> [<secret vaule> | @<secret file>]
#
# The script will write a secret object with two field: format and value.
# "format" can be text or binary based on the input data. If the data is binary, the code will
# base64 encode it and store in vault in "value" field.
#
# See vault-read.sh to read back data. 
 
THIS_DIR=$(dirname "$0")

set -u
VAULT_ADDR=${VAULT_ADDR:-https}
path="$1"
input="$2"

if ! vault --version | grep 'v1.' &> /dev/null
then
    (>&2 echo "The vault version is too old, please upgrade the vault cmd.")
    exit 1
fi


if [[ "$input" =~ ^@ ]];
then
    # if the data is in a file
    src=$(echo $2 | cut -c 2-)
    if file -b --mime-encoding $src | grep -s binary > /dev/null
    then
        # if data is binary, base64 encode it and set format=base64
        cat $src | base64 | vault kv put $path value=- format="base64"
    else
        # otherwise set format=text
        cat $src | vault kv put $path value=- format="text"
    fi
else
    vault kv put $path value="$2" format="text"
fi


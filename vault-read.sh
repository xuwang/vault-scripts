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
#
# Usage:
#   vault-read <path>
#
# Assumption: a secret object has two field: format and value.
# "format" can be text or base64, "value" is the actual data.
# The code will output value either in text or base64 decoded value.

THIS_DIR=$(dirname "$0")

set -u
VAULT_ADDR=${VAULT_ADDR}
path=$1

if ! vault --version | grep 'v1.' &> /dev/null
then
    (>&2 echo "The vault version is too old, please upgrade the vault cmd.")
    exit 1
fi

# Get the kv sec from $path in json
j=$(vault kv get -format=json $path)

return_code=$?
if [ "$return_code" -ne "0" ]; then
    exit $return_code
fi

f=$(echo "$j" | jq -r '.data.format//.data.data.format' 2> /dev/null)
v=$(echo "$j" | jq -r '.data.value//.data.data.value')

# if value format is base64, decode it
if [ "base64" == "$f" ]
then
    echo -n "$v" | base64 --decode
else
    echo -n "$v"
fi

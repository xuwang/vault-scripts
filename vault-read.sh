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
# Assumption: a secret object has two fields: format and value.
# "format" can be text or base64, "value" is the actual data.
# The code will output value either in text or base64 decoded value.

SCRIPT_NAME=$(basename "$0")
if [ "$#" != "1" ]; then
    echo usage "$SCRIPT_NAME: <secret-path>"
    exit 1
else
    path=$1
fi

VAULT_ADDR=${VAULT_ADDR:-https://vault.example.com}

# Get the kv secret from path in json
data=$(vault kv get -format=json $path)
if [ "$?" != "0" ]; then
    exit 1
fi

f=$(echo "$data" | jq -r '.data.format//.data.data.format' 2> /dev/null)
v=$(echo "$data" | jq -r '.data.value//.data.data.value')

# if value format is base64, decode it
if [ "base64" == "$f" ]
then
    echo -n "$v" | base64 --decode
else
    echo -n "$v"
fi

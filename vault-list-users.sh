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
# Usage:
#   vault-list-users.sh [<userid>]

# include functions
THIS_DIR=$(dirname "$0")
source $THIS_DIR/functions.sh

user=$1
tmpfile=$(mktemp)

function list_aliases() {
  vault list -format json  identity/entity-alias/id  | jq -r '.[]' > $tmpfile
}

function list_all_users() {
  for i in `cat $tmpfile`
  do
    vault read -format=json identity/entity-alias/id/$i  | jq -r '.data.name'
  done
}

function get_user() {
  for i in `cat $tmpfile`
  do
    vault read -format=json identity/entity-alias/id/$i  | \
        jq -r ".data | select(.name==\"$user\")" > $tmpfile.$user
    if [ -s "$tmpfile.$user" ]; then
      cat $tmpfile.$user
      break
    fi
  done
}

# MAIN

if vault token lookup > /dev/null 2>&1 ; then
  admin=$(vault token lookup -format=json | jq -r '.data.display_name')
  echo "Using $admin token to lookup vault users."
else 
  echo "Valid vault token is required. Please run vault login."
  exit 1
fi

list_aliases

if [ ! -z "$user" ]; then
  get_user
else
  list_all_users
fi

rm -rf $tmpfile $tmpfile.$user
 

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

###############################################################################
# Helper functions
###############################################################################

# colors
yellow='\[\033[0;33m\]'
red='\[\033[0;31m\]'
reset='\[\033[0m\]'

# http://stackoverflow.com/a/25515370
yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "cannot $*"; }

err() {
  echo
  echo ${red}ERROR: ${@}$reset
  echo
  exit 1
}

err_report() {
  echo "$1: error on line $2"
}

trap_errors() {
  if [ "$debug_scripts" = "true" ]; then
    set -x
  fi

  set -eeuo pipefail
  trap 'err_report $BASH_SOURCE $LINENO' err
  export shellopts
}

# check if a variable is set. useful for set -u
is_set() {
  declare -p $1 &> /dev/null
}

# is the variable set and have length?
not_empty_var() {
  is_set $1 && eval val=\$$1 && [[ "$val" ]]
}

# is the variable unset or zero length? useful for set -u
empty_var() {
   ! not_empty_var $1
}

is_null() {
  [[ $1 == "null" ]]
}

is_null_or_empty() {
  [[ $1 == "null" ]] || [[ -z "${1// }" ]]
}

confirm() {
  ## Ask to confirm an action
  echo "$*"
  echo "CONTINUE? [Y/N]: "; read ANSWER
  [[ $ANSWER == "Y" ]]
}

get_root_dir() {
  local f
  if [[ $1 == /* ]]; then f=2; else f=1; fi
  echo "$1" | cut -d "/" -f$f
}

# test if a path is a KV v2 path
is_kv() {
  local kv_mount=$(get_root_dir $1)
  vault secrets list -format=json \
    | jq -re --arg v "$kv_mount/" '.[$v] | select(((.type=="kv") or (.type=="generic")) and (.options.version=="2"))' \
    | grep version &>/dev/null
}

vault_read_cmd() {
    echo "vault kv get"
}

vault_write_cmd() {
    echo "vault kv put"
}

vault_list_cmd() {
    echo "vault kv list"
}

urlencode() {
    # urlencode <string>
    old_lc_collate=$LC_COLLATE
    LC_COLLATE=C
    
    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done
    
    LC_COLLATE=$old_lc_collate
}

urldecode() {
    # urldecode <string>

    local url_encoded="${1//+/ }"
    printf '%b' "${url_encoded//%/\\x}"
}

export -f yell die try err err_report trap_errors is_set not_empty_var empty_var confirm is_null is_null_or_empty get_root_dir
export -f is_kv vault_read_cmd vault_write_cmd vault_list_cmd
export -f urlencode urldecode

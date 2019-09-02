#!/bin/bash -e
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
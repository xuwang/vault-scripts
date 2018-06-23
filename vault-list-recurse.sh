#!/bin/bash -e
# List all kv path recusivily from a give path
# Usage:
#   vault-list-recurse <path>

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
    echo $*
    exit 1
}

######
# Main
######

if [ -z "$1" ]
then
    abort "Error: Vault KV root path is required."
else
    root=$1
    root=${@%/}  # Remove trailing slash if any. Will add it back later
fi 

# If Vault version is 0.10.x, use vault kv list command
vault_list="vault list"
if vault -version | grep -q v0.10 ; then
  vault_list="vault kv list"
fi

if $vault_list $root
then
    list $root/
else
    abort "Error: '$root' is not a valid Vault kv path."
fi

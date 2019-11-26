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
THIS_DIR=$(dirname "$0")

# include functions
source $THIS_DIR/functions.sh

vault_info() {
    export VAULT_ADDR=${VAULT_ADDR}
    VAULT_AUTH_METHOD=${VAULT_AUTH_METHOD:-ldap}
    SEC_PATH=${SEC_PATH:-auth/token/lookup-self}

    echo "VAULT SERVER: $VAULT_ADDR"
    # seal status (0 unsealed, 2 sealed, 1 error)
    vault status
    [[ $? -eq 1 ]] && die "Error checking vault status."
    if vault-list.sh ${SEC_PATH} 2>&1 >/dev/null | grep 'missing client token' 2>&1 >/dev/null
    then
        echo "You are not logged in VAULT"
    elif vault-list.sh ${SEC_PATH} 2>&1 >/dev/null | grep 'permission denied' 2>&1 >/dev/null
    then
        echo "You are logged in VAULT but you don't have permissions to access ${SEC_PATH}"
    else
        echo "You are logged in VAULT and has the access to ${SEC_PATH}"
        vault read auth/token/lookup-self
    fi
}

vault_info

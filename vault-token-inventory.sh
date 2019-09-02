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

###############################################################################
# List current tokens's properties using token accessors.
###############################################################################

set +u # optional vars
export VAULT_ADDR=${VAULT_ADDR:-https://127.0.0.1:8200}
export VAULT_SEC_PATH=${VAULT_SEC_PATH:-auth/token/lookup-self}
export VAULT_AUTH_PATH=${VAULT_AUTH_PATH:-ldap}
export VAULT_AUTH_METHOD=${VAULT_AUTH_METHOD:-ldap}
export VAULT_USER=${LOGNAME:-$USER}

set -u

echo "VAULT ADDR: $VAULT_ADDR"

if ! vault status > /dev/null 2>&1; then
    echo "Cannot check $VAULT_ADDR status. Need to set VAULT_ADDR?"
    exit 1
fi

if ! vault token lookup > /dev/null 2>&1; then
    echo "Hey $VAULT_USER: Please login VAULT with DUO device ready. Waiting...:"
    vault login -method=${VAULT_AUTH_METHOD} -path=${VAULT_AUTH_PATH}
fi

if vault token capabilities ${VAULT_SEC_PATH}/* | grep -q root; then
    echo "You are logged in VAULT with root token!"
fi

if vault token capabilities auth/tokens/accessors | grep -q deny; then
     >&2 "ERROR: no permission to list auth/tokens/accessors" && false
else
    vault list -format=json auth/token/accessors | jq -r '.[]' | tee /tmp/token-accessors.$$
    for i in `cat /tmp/token-accessors.$$`
    do
      echo
      echo Look up with token accessor $i
      if ! vault token lookup --format=json --accessor $i 2>/dev/null >> /tmp/token-$$.json; then
        # Get the errors
        echo vault token lookup --format=json --accessor $i
      fi
    done
fi
rm -rf /tmp/token-accessors.$$
echo Token inventory  is saved in /tmp/token-$$.json

echo Usefull tricks:
echo "cat /tmp/token-$$.json | jq -r [.data] | jq '.[] | select(.meta.username==\"foobar\")'"
echo "cat /tmp/token-$$.json | jq -r [.data] | jq '.[] | select(.meta.username==\"foobar\").policies'"

echo Get all the root info:
echo "cat /tmp/token-$$.json | jq -r '[.data][] | select(.policies[] | contains(\"root\"))'"
echo "cat /tmp/token-$$.json | jq -r '[.data][] | select(.policies[] | contains(\"root\")) | .accessor'"
echo "To revoke a token by accessor: vault token revoke --accessor <accessor>"

# Vault Secrets the Simple Way

This article introduces a simple way of working with [Hashicorp Vault](https://github.com/hashicorp/vault) key-value secrets engine.

## Prerequisites

You should have a running Hashicorp/Vault service and [Vault](https://www.vaultproject.io/downloads/) command available.

Here is a quick way to install a [Vault dev server](https://learn.hashicorp.com/vault/getting-started/dev-server)

## Challenge

The basic form of using key-value secret backend is simple:

* Put a secret in vault

```console

$ vault kv put secret/test-me username=me password=changeme
Key              Value
---              -----
created_time     2020-02-21T19:10:19.074035078Z
deletion_time    n/a
destroyed        false
version          1
```

* Get  secret from vault

```console
$ vault kv get -format=json secret/test-me
Handling connection for 8443
{
  ...
  "renewable": false,
  "data": {
    "data": {
      "password": "changeme",
      "username": "me"
    },
    ...
}
```

The data in key-value store can be of any type, such as SSL certificates, application configurations containing secrets, binary data, database connection strings with credentials. 

The data  input can come from command line, from a program, from Vault secret plugin provider, etc. etc.

Vault users usually design their vault secret input key field based on their application, get the secret with the same key field,
and process the data based on type of content. For example, database admins may put secret with *db-user=\<user\> password=\<password\>*,
an authentication app may use *login=\<user\> password=\<password\>*, or another app may do *key_id=\<app key\> key_secret=\<key secret\>*.

In addition to all kinds of input fields, for binary data, you need to base64-encode secret first before putting it in Vault, and base64-decode it after reading
back from Vault.

This presents a challenge in a team environment that secrets are treated like pets, handled differently by developing different tools that need to know how the data is put into Vault.

For example, for the *username=me password=changeme* secret we added, we can get value back with *-field=username and -field=password*:

```console
$ vault kv get -field=username secret/test-me
me
$ vault kv get -field=password secret/test-me
changeme
```

Another secret might use different field name:

```console
$ vault kv get -field=login secret/another-test-me
another-me
$ vault kv get -field=secret secret/another-test-me
changeme-too
```

This can quickly get out of control when you have many secrets, many people, and many applications need to access
the secretes.

## Solution

Although each secret is unique, we can **standardize input field name** with a team-agreed convention so 
the same field can be used to get the content of a secret, or to test the type of a secret, no matter what kind of secret it is.

## The Field Naming Convention

In our environment, we require all secrets contain two *key=value* fields, namely:

* **format**: this indicates the type of data. Can be "text" or "base64"
* **value**: this is the actual secret content. Can be quoted strings, a text file, or a binary file.

Using this convention, let's put a second version of the *test-me* secret with content from a json file */tmp/my-secret.json*:

```console
{
  "username": "me",
  "password": "changeme",
}
```

Then write to vault with *format=text* and *value=@/tmp/my-secret* field:

```
$ vault kv put secret/test-me format=text value=@/tmp/my-secret
Key              Value
---              -----
created_time     2020-02-21T22:06:15.801274628Z
deletion_time    n/a
destroyed        false
version          2
```

Get secret from vault with *value* and *format* field:

```
$ vault kv get -field=value secret/test-me
{
  "username": "me",
  "password": "changeme",
}

$ vault kv get -field=format secret/test-me
text
```

Note we get the data with common *field=value* convention. We also can use *field=format* to decide if we need base64 decode.

We have developed with two simple scripts **vault-write.sh** and **vault-read.sh** to make it even easier to use based on this convention. 

## Vault-write.sh

```console
#!/bin/bash
#
# Usage: vault-write <path> ["secret strings>" | @<secret file>]

SCRIPT_NAME=$(basename "$0")
VAULT_ADDR=${VAULT_ADDR:-https://vault.example.com}
if [ "$#" != "2" ]; then
    echo usage "$SCRIPT_NAME: <path> [\"<secret strings>\" | @<secret file>]"
    exit 1
fi

path=$1

if [[ "$2" =~ ^@ ]];
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
```

The *vault-write.sh* accepts a secret path and a secret value either as string or a file. It decides
if the data needs base64 encoding based on the content of the secret.

Let's now write a binary file to *secret/test-me* path. 

```console
$ vault-write.sh secret/test-me @/tmp/gitlab.png
Key              Value
---              -----
created_time     2020-02-21T22:47:57.918585831Z
deletion_time    n/a
destroyed        false
version          3

$ vault kv get --format=json secret/test-me
{
  ...
  "data": {
    "data": {
      "format": "base64",
      "value": "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\n"
    },
}
```
Our 3rd version of *test-me* is base64 encoded and stored in Vault with **format=base64 value=\<encoded content\>** by *vault-write.sh* automatically.

We can use *vault kv get -field=value secret/test-me | base64 --decode > /tmp/gitlab1.png* to get the binary file back or use our next script **vault-read.sh**.

## Vault-read.sh

```console
#!/bin/bash
# Usage: vault-read <secret-path>

SCRIPT_NAME=$(basename "$0")
if [ "$#" != "1" ]; then
    echo usage "$SCRIPT_NAME: <secret-path>"
    exit 1
else
    path=$1
fi
export VAULT_ADDR=${VAULT_ADDR:-https://vault.example.com}

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
```

This code reads from key-value store and if the *format* field is base64, it will run base64 decode to decode the content. Since the 3rd version of the secret 
is a png binary file, let's save it to a file instead of output to standard out.

```console
$ vault-read.sh secret/test-me > /tmp/gitlab2.png
```

You can compare /tmp/gitlab.png (original file), /tmp/gitlab1.png and /tmp/gitlab2.png, they are all the same png binary format file.

## Cleanup

To delete all versions created in this exercise:

```console
$ vault kv metadata delete secret/test-me
Success! Data deleted (if it existed) at: secret/metadata/test-me
$ vault kv get  secret/test-me 
No value found at secret/data/test-me
```

## Summary

We defined a convention so that all vault secret objects have two common fields: **format=[text|base64]** and **value=[strings|@file]**.
 
Now We can get any secret's content by **value** field, and use the content of **format** field to decide if we need to run base64 decode.

We can also introduced simple [vault-read.sh](./vault-read.sh) and [vault-write.sh](./vault-write.sh) scripts which not only make it easy for operators and applications alike to store and get secrets from vault with auto-type detecting, base64-encoding and base64-decoding, but also help us to enforce the field naming convention.

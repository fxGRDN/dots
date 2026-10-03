#!/bin/sh
# Prints the OAuth2 login meli passes to IMAP/SMTP (base64 XOAUTH2 string).
# Usage: oauth2-token.sh <google|microsoft> <email>
# First run per account (opens the browser to sign in): oauth2-token.sh <provider> <email> --authorize
#
# Tokens live in GNOME Keyring, keyed by address. mutt_oauth2.py insists on a token
# file, but with these pipes it stays empty.
if [ $# -lt 2 ]; then
    echo "usage: $0 <google|microsoft> <email> [--authorize]" >&2
    exit 1
fi
provider=$1
email=$2

file="$HOME/.local/share/meli/oauth2/$email"
store="secret-tool store --label='meli oauth2 $email' service meli-oauth2 account $email"
lookup="secret-tool lookup service meli-oauth2 account $email"
helper="$HOME/.local/bin/mutt_oauth2.py"
mkdir -p "$(dirname "$file")"

if [ "$3" = "--authorize" ]; then
    exec python3 "$helper" --verbose --authorize --provider "$provider" --authflow localhostauthcode \
        --email "$email" --encryption-pipe "$store" --decryption-pipe "$lookup" "$file"
fi

token=$(python3 "$helper" --email "$email" --encryption-pipe "$store" --decryption-pipe "$lookup" "$file") || exit 1
printf 'user=%s\001auth=Bearer %s\001\001' "$email" "$token" | base64 -w0

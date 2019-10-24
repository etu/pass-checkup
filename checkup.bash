#!/usr/bin/env bash
# pass checkup - Password Store Extension (https://www.passwordstore.org/)
# Copyright (C) 2019 Elis Hirwing
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
# []

VERSION="0.1.0"

CURL=$(command -v curl)
FIND=$(command -v find)
GREP=$(command -v grep)
HEAD=$(command -v head)
SED=$(command -v sed)
SHA1SUM=$(command -v sha1sum)
SORT=$(command -v sort)
TR=$(command -v tr)

# Function to call that determines if we're looking for a file or a directory
# and then calls the right function to check all files in that directory or
# just that file.
cmd_checkup_check() {
    local path="${1%/}"
    local passdir="$PREFIX/$path"
    local passfile="$PREFIX/$path.gpg"

    check_sneaky_paths "$path"

    # If we're getting a directory, send it to a separate function
    if test -d "$passdir"; then
        cmd_checkup_check_dir "$path"
        exit 0
    fi

    if test -f "$passfile"; then
        cmd_checkup_check_file "$path"
        exit 0
    fi

    echo "${path}: pass file or directory not found."
    exit 1
}

# Locate all files in the directory that ends with .gpg and send them to the
# function that checks by file.
cmd_checkup_check_dir() {
    local path="${1%/}"
    local passdir="$PREFIX/$path"

    check_sneaky_paths "$path"

    $FIND "$passdir" -type f -name '*.gpg' | $SORT | $SED -e "s#${PREFIX}/##" -e "s#.gpg##" | while read fname; do
        cmd_checkup_check_file "$fname"
    done
}

# Function that checks if a password is leaked or not.
cmd_checkup_check_file() {
    local path="${1%/}"
    local passfile="$PREFIX/$path.gpg"

    check_sneaky_paths "$path"
    [[ ! -f "$passfile" ]] && die "$path: passfile not found."

    # Get password hash
    # Decrypt the file, get first line, trim away newlines, hash it
    hash=$($GPG -d "${GPG_OPTS[@]}" "$passfile" | $HEAD -n 1 | $TR -d '\n' | $SHA1SUM)

    # Get the 5 first characters of the hash
    startOfHash=${hash::5}

    # Get the rest 35 characters of the hash for searching
    endOfHash=${hash:5:35}

    # Get filtered leaked hashes
    leakedHashes=$($CURL -H 'user-agent: pass-checkup-extension; github.com/etu/pass-checkup' -s "https://api.pwnedpasswords.com/range/${startOfHash}" | $GREP -i $endOfHash)

    # Define some color codes
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    NC='\033[0m' # No Color

    # Check if password is leaked or not
    if test $(echo -n $leakedHashes | wc -c) = 0; then
        echo -e "${GREEN}${path}: Password is probably not leaked ✔️${NC}"
    else
        echo -e "${RED}${path}: Password is leaked ❌${NC}"
    fi
}

cmd_checkup_version() {
    echo $VERSION
    exit 0
}

cmd_checkup_usage() {
    cat <<-EOF
Usage:

    $PROGRAM checkup [pass-name]
        Check if a password is publicly leaked through HaveIbeenPwned's api.

        If no [pass-name] is supplied, we'll check all passwords.

    $PROGRAM checkup [help|--help|-h]
        Print this help page.

    $PROGRAM checkup --version
        Print version of this extension.

EOF
    exit 0
}

case "$1" in
    help|--help|-h)       shift; cmd_checkup_usage ;;
    version|--version|-v) shift; cmd_checkup_version ;;
    check)                shift; cmd_checkup_check "$@" ;;
    *)                           cmd_checkup_check "$@" ;;
esac

exit 0

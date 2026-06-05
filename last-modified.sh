#!/bin/sh
#
# Copyright 2026 r1w1s1
# All rights reserved.
#
# Redistribution and use of this script, with or without modification, is
# permitted provided that the following conditions are met:
#
# 1. Redistributions of this script must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED
#  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
#  EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# last-modified.sh - set a note's "Last Modified:" footer.
#   sh last-modified.sh FILE                         -> today (UTC)
#   sh last-modified.sh FILE "YYYY-MM-DD [HH:MM:SS]" -> backfill

set -eu

[ $# -ge 1 ] || { echo "usage: $0 FILE [\"YYYY-MM-DD [HH:MM:SS]\"]" >&2; exit 1; }
file=$1
[ -f "$file" ] || { echo "not found: $file" >&2; exit 1; }

RULE=$(printf '%066d' 0 | tr 0 -)   # 66-dash rule, matches the notes' footer width

if [ $# -ge 2 ]; then
	case "$2" in
		*' '*[0-9]) stamp="$2 UTC" ;;
		*) stamp="$2 00:00:00 UTC" ;;
	esac
else
	stamp=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
fi

tmp=$(mktemp)
grep -v '^Last Modified:' "$file" > "$tmp"

# strip trailing blanks and any old rule so re-running never stacks footers
while [ -s "$tmp" ] && tail -n 1 "$tmp" | grep -Eq '^[[:space:]]*$|^-{3,}$'; do
	sed -i '$d' "$tmp"
done

{ echo; echo; echo "$RULE"; echo; echo "Last Modified: $stamp"; } >> "$tmp"
mv "$tmp" "$file"
echo "set $file -> $stamp"

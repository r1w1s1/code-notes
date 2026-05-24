#!/bin/sh

set -eu

if [ $# -ne 1 ]; then
    echo "Usage: $0 FILE"
    exit 1
fi

file="$1"

if [ ! -f "$file" ]; then
    echo "Error: file not found: $file"
    exit 1
fi

timestamp=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

tmp=$(mktemp)

# remove old Last Modified lines
grep -v '^Last Modified:' "$file" > "$tmp"

# remove trailing blank lines
while [ -s "$tmp" ] && tail -n 1 "$tmp" | grep -q '^[[:space:]]*$'; do
    sed -i '$d' "$tmp"
done

# append footer
{
    echo
    echo "Last Modified: $timestamp"
} >> "$tmp"

mv "$tmp" "$file"

echo "Updated: $file"

#!/bin/bash
# Check if a file name is provided
if [ -z "$1" ]; then
  echo "Usage: $0 NAME_OF_DOCUMENT.txt"
  exit 1
fi

FILE_PATH="$1"

# Check if the file exists
if [ ! -f "$FILE_PATH" ]; then
  echo "Error: File '$FILE_PATH' does not exist."
  exit 1
fi

# Get current UTC date (date only, no time)
CURRENT_DATE=$(date -u +"%Y-%m-%d")
LAST_MODIFIED_LINE="Last Modified: $CURRENT_DATE"

# Remove existing "Last Modified:" line and any blank lines before it at end of file
sed -i '/^Last Modified:/d' "$FILE_PATH"

# Strip trailing blank lines from end of file
sed -i -e :a -e '/^\s*$/{$d;N;ba}' "$FILE_PATH"

# Append 2 blank lines + Last Modified line
printf "\n\n%s\n" "$LAST_MODIFIED_LINE" >> "$FILE_PATH"

echo "Last Modified date updated in '$FILE_PATH': $CURRENT_DATE"

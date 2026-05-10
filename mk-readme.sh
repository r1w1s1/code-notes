#!/bin/sh

OUT=README
NOTES=notes

cat <<'EOF' > "$OUT"
CODE-NOTES

code-notes is a small collection of concise technical notes.

The notes primarily cover Slackware Linux, Unix system administration,
package mirrors, QEMU, editors, and simple tools.

All documents are written in plain text.


DOCUMENTS

NOTE: The list below is generated from the notes/ directory.

The following notes are available under notes/:

EOF

find "$NOTES" -maxdepth 1 -type f -name '*.txt' \
    | sort \
    | while read -r f; do
        printf -- "- %s\n" "$(basename "$f")"
      done >> "$OUT"


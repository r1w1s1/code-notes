#!/bin/sh
# generate-rss.sh - build an RSS 2.0 feed from notes/*.txt
#
#   title = first line of each note
#   date  = the "Last Modified:" footer
#   link  = $BASE_URL/notes/<file>
#
# Run from the repo root:
#   sh generate-rss.sh > rss.xml

set -eu

#
# Configuration
#

BASE_URL="https://repo.or.cz/code-notes.git/blob_plain/HEAD:"
FEED_LINK="https://repo.or.cz/code-notes.git"
FEED_TITLE="code-notes"
FEED_DESC="Concise technical notes on Slackware, Unix, and minimal tooling."

NOTES="notes"

#
# Helpers
#

esc()
{
    sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'
}

now=$(date -u +"%a, %d %b %Y %H:%M:%S +0000")

#
# Feed header
#

cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
<channel>
<title>$FEED_TITLE</title>
<link>$FEED_LINK</link>
<description>$FEED_DESC</description>
<lastBuildDate>$now</lastBuildDate>
<atom:link href="${BASE_URL}/rss.xml" rel="self" type="application/rss+xml" />
EOF

#
# Collect notes and sort by Last Modified date
#

for f in "$NOTES"/*.txt; do
    [ -f "$f" ] || continue

    d=$(grep '^Last Modified:' "$f" | tail -n 1 |
        sed 's/^Last Modified:[[:space:]]*//; s/ UTC$//')

    [ -n "$d" ] || continue

    printf '%s\t%s\n' "$d" "$f"
done |
sort -r |
while IFS="$(printf '\t')" read -r d f; do

    title=$(head -n 1 "$f" | esc)
    url="$BASE_URL/$f"

    pub=$(date -u -d "$d UTC" \
        +"%a, %d %b %Y %H:%M:%S +0000" 2>/dev/null ||
        echo "$now")

    # excerpt:
    #   - drop title
    #   - drop box drawing lines (+ |)
    #   - drop separators (--- ===)
    #   - drop footer
    #   - drop blank lines
    excerpt=$(sed '1d' "$f" |
        grep -Ev '^[[:space:]]*[|+]' |
        grep -Ev '^[[:space:]]*[-=]{3,}[[:space:]]*$' |
        grep -v '^Last Modified:' |
        sed '/^[[:space:]]*$/d' |
        head -n 3 |
        tr '\n' ' ' |
        sed 's/[[:space:]]\{2,\}/ /g' |
        cut -c1-280)

    cat <<EOF
<item>
<title>$title</title>
<link>$url</link>
<guid isPermaLink="true">$url</guid>
<pubDate>$pub</pubDate>
<description><![CDATA[$excerpt]]></description>
</item>
EOF

done

#
# Feed footer
#

cat <<EOF
</channel>
</rss>
EOF

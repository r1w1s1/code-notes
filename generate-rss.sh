#!/bin/sh
# generate-rss.sh - build an RSS 2.0 feed from notes/*.txt
#   title = first line of each note
#   date  = the "Last Modified:" footer
#   link  = $BASE_URL/notes/<file>   (canonical permalink = the filename)
# Run from the repo root:  sh generate-rss.sh > rss.xml

set -eu

BASE_URL="https://git.sr.ht/~r1w1s1/code-notes/blob/main"
FEED_LINK="https://git.sr.ht/~r1w1s1/code-notes"
FEED_TITLE="code-notes"
FEED_DESC="Concise technical notes on Slackware, Unix, and minimal tooling."
NOTES=notes

esc() { sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }   # XML-escape element text

now=$(date -u +"%a, %d %b %Y %H:%M:%S +0000")

cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
<channel>
<title>$FEED_TITLE</title>
<link>$FEED_LINK</link>
<description>$FEED_DESC</description>
<lastBuildDate>$now</lastBuildDate>
EOF

for f in "$NOTES"/*.txt; do
	[ -f "$f" ] || continue
	d=$(grep '^Last Modified:' "$f" | tail -n 1 \
		| sed 's/^Last Modified:[[:space:]]*//; s/ UTC$//')
	[ -n "$d" ] || continue              # skip notes that still have no date
	printf '%s\t%s\n' "$d" "$f"
done \
| sort -r \
| while IFS="$(printf '\t')" read -r d f; do
	title=$(head -n 1 "$f" | esc)
	url="$BASE_URL/$f"
	pub=$(date -u -d "$d UTC" +"%a, %d %b %Y %H:%M:%S +0000" 2>/dev/null || echo "$now")
	# excerpt: drop title, box-drawing (+ |), rules (--- ===), footer, blanks
	excerpt=$(sed '1d' "$f" \
		| grep -Ev '^[[:space:]]*[|+]' \
		| grep -Ev '^[[:space:]]*[-=]{3,}[[:space:]]*$' \
		| grep -v '^Last Modified:' \
		| sed '/^[[:space:]]*$/d' \
		| head -n 3 | tr '\n' ' ' | sed 's/[[:space:]]\{2,\}/ /g' | cut -c1-280)
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

cat <<EOF
</channel>
</rss>
EOF

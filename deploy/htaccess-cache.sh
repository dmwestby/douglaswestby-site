#!/usr/bin/env bash
# Runs ON THE SERVER (piped over SSH by the deploy workflow).
# Adds or refreshes one marked block in public_html/.htaccess so browsers and
# Cloudflare re-check the home page and CV on every visit instead of serving a
# stale copy. Everything else in .htaccess is left exactly as it was, and a
# one-time backup is kept as .htaccess.bak-douglaswestby-site.
set -euo pipefail
cd "$1"
f=.htaccess
begin='# BEGIN douglaswestby-site cache'
end='# END douglaswestby-site cache'
touch "$f"
[ -e "$f.bak-douglaswestby-site" ] || cp -p "$f" "$f.bak-douglaswestby-site"
tmp=$(mktemp)
awk -v b="$begin" -v e="$end" '$0==b{skip=1;next} $0==e{skip=0;next} !skip' "$f" > "$tmp"
# drop a trailing blank line left from a previous block
sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$tmp"
cat >> "$tmp" <<BLOCK

$begin
<IfModule mod_headers.c>
  <FilesMatch "^(index\.html|Douglas-Westby-CV\.pdf)$">
    Header set Cache-Control "no-cache, must-revalidate"
  </FilesMatch>
</IfModule>
$end
BLOCK
cat "$tmp" > "$f"
rm -f "$tmp"
echo "Updated $f cache block:"
sed -n "/$begin/,/$end/p" "$f"

#!/usr/bin/env bash
# Runs ON THE SERVER (piped over SSH by the deploy workflow).
# Usage: htaccess-redirects.sh <docroot> [remove]
#
# Keeps one marked block at the TOP of public_html/.htaccess with redirects for
# douglaswestby.com only:
#   - www.douglaswestby.com            -> https://douglaswestby.com
#   - http:// (as reported by the CDN) -> https://
#   - old WordPress pages and posts    -> the matching section of the new page
# Every rule checks the host name, so the other sites in public_html are never
# affected. Everything else in .htaccess is left exactly as it was, and a
# one-time backup is kept as .htaccess.bak-douglaswestby-site.
# With "remove", the block is taken out again (used by the workflow's
# post-deploy check if the home page stops loading).
set -euo pipefail
cd "$1"
mode="${2:-apply}"
f=.htaccess
begin='# BEGIN douglaswestby-site redirects'
end='# END douglaswestby-site redirects'
touch "$f"
[ -e "$f.bak-douglaswestby-site" ] || cp -p "$f" "$f.bak-douglaswestby-site"

rest=$(mktemp)
out=$(mktemp)
awk -v b="$begin" -v e="$end" '$0==b{skip=1;next} $0==e{skip=0;next} !skip' "$f" > "$rest"
# drop leading blank lines left from a previous block
sed -i '/./,$!d' "$rest"

if [ "$mode" = "remove" ]; then
  cat "$rest" > "$out"
else
  cat > "$out" <<'BLOCK'
# BEGIN douglaswestby-site redirects
<IfModule mod_rewrite.c>
  RewriteEngine On

  # www -> bare domain, always https
  RewriteCond %{HTTP_HOST} ^www\.douglaswestby\.com$ [NC]
  RewriteRule ^(.*)$ https://douglaswestby.com/$1 [R=301,L]

  # http -> https. HTTPS ends at the Bluehost CDN, so only redirect when the
  # CDN says the visitor used plain http (this can never loop).
  RewriteCond %{HTTP_HOST} ^douglaswestby\.com$ [NC]
  RewriteCond %{HTTP:X-Forwarded-Proto} ^http$ [NC,OR]
  RewriteCond %{HTTP:CF-Visitor} \Whttp\W\}$ [NC]
  RewriteRule ^(.*)$ https://douglaswestby.com/$1 [R=301,L]

  # Old WordPress pages -> sections of the new page
  RewriteCond %{HTTP_HOST} ^douglaswestby\.com$ [NC]
  RewriteRule ^about-me/?$ https://douglaswestby.com/#about [R=301,NE,L]
  RewriteCond %{HTTP_HOST} ^douglaswestby\.com$ [NC]
  RewriteRule ^resume/?$ https://douglaswestby.com/#experience [R=301,NE,L]
  RewriteCond %{HTTP_HOST} ^douglaswestby\.com$ [NC]
  RewriteRule ^contact/?$ https://douglaswestby.com/#contact [R=301,NE,L]

  # Old WordPress pages, posts, archives and feeds with no new equivalent -> home
  RewriteCond %{HTTP_HOST} ^douglaswestby\.com$ [NC]
  RewriteRule ^(home|professional-services|blog|portfolio|risk-management|sample-page|feed|comments/feed)/?$ https://douglaswestby.com/ [R=301,L]
  RewriteCond %{HTTP_HOST} ^douglaswestby\.com$ [NC]
  RewriteRule ^(navigating-the-future-the-current-state-of-the-art-in-project-management|le-deliclassy-a-cozy-coffee-corner-in-corozal|blues-bites-lounge-a-seaside-escape-with-coffee-music-and-vibes|creating-a-concept-for-a-mascot-with-chatgpt-4|heres-how-you-can-create-a-successful-project-plan-in-a-few-steps)/?$ https://douglaswestby.com/ [R=301,L]
  RewriteCond %{HTTP_HOST} ^douglaswestby\.com$ [NC]
  RewriteRule ^(category|tag|author|portfolio-item|20[0-9][0-9])(/.*)?$ https://douglaswestby.com/ [R=301,L]

  # Old WordPress ?p=123 / ?page_id=123 links -> home
  RewriteCond %{HTTP_HOST} ^douglaswestby\.com$ [NC]
  RewriteCond %{QUERY_STRING} (^|&)(p|page_id)=[0-9]+(&|$)
  RewriteRule ^(index\.php)?$ https://douglaswestby.com/ [R=301,QSD,L]
</IfModule>
# END douglaswestby-site redirects
BLOCK
  if [ -s "$rest" ]; then printf '\n' >> "$out"; cat "$rest" >> "$out"; fi
fi

cat "$out" > "$f"
rm -f "$rest" "$out"
echo "Updated $f ($mode). Redirect block now:"
sed -n "/$begin/,/$end/p" "$f"

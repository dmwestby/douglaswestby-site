#!/usr/bin/env bash
# Runs ON THE SERVER (piped over SSH by the deploy workflow).
# Usage: check-redirects.sh <origin-ip>
# Asks the web server directly (skipping the Bluehost CDN, which blocks
# automated requests from GitHub with 403) how it answers douglaswestby.com
# requests, the same way the CDN forwards them. Exits 1 only if the home page
# no longer loads, so the workflow can take the redirect block out again.
set -uo pipefail
ip="$1"
req() { # host proto path
  curl -s -o /dev/null -m 15 -w '%{http_code} %{redirect_url}' \
    -H "Host: $1" -H "X-Forwarded-Proto: $2" "http://$ip/$3" || echo "000"
}
home=$(req douglaswestby.com https "?deploycheck=$$")
echo "https://douglaswestby.com/          -> $home"
echo "http://douglaswestby.com/           -> $(req douglaswestby.com http '')"
echo "https://www.douglaswestby.com/      -> $(req www.douglaswestby.com https '')"
echo "https://douglaswestby.com/resume/   -> $(req douglaswestby.com https resume/)"
echo "https://douglaswestby.com/?p=12     -> $(req douglaswestby.com https '?p=12')"
case "$home" in
  200*) echo "Home page loads."; exit 0 ;;
  *) echo "Home page did not return 200."; exit 1 ;;
esac

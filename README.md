# douglaswestby-site

Source for douglaswestby.com.

Pushes to `main` deploy to Bluehost (`/home4/zgaxnhmy/public_html/`) through
`.github/workflows/deploy.yml`, over SSH with rsync. The deploy never deletes
anything on the server, because `public_html` also holds other sites
(`website_*` folders) and cPanel files. Run the workflow manually from the
Actions tab with "dry run" ticked to preview what would be uploaded.

Secrets used: `SSH_PRIVATE_KEY`, `SSH_HOST`, `SSH_PORT`, `SSH_USER`.

After uploading, the workflow also runs `deploy/htaccess-cache.sh` on the
server. It keeps one marked block in `public_html/.htaccess` that tells
browsers and Cloudflare to re-check `index.html` and the CV PDF on each visit,
so updates show up straight away. The rest of `.htaccess` is left alone, and
the first run saves a backup as `.htaccess.bak-douglaswestby-site`.

It then runs `deploy/htaccess-redirects.sh`, which keeps a second marked block
at the top of `public_html/.htaccess`. It sends `www.douglaswestby.com` and
plain `http://` visits to `https://douglaswestby.com`, and sends the old
WordPress addresses (`/resume/`, `/about-me/`, `/contact/`, blog posts and so
on) to the matching part of the new page. Every rule checks the host name, so
the other sites in `public_html` are not affected. After that the workflow
loads the live home page; if it does not come back with HTTP 200, the redirect
block is removed again automatically and the run is marked failed.

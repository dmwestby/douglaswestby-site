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

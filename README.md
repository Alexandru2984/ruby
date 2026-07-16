# Bookmarks

[![CI](https://github.com/Alexandru2984/ruby/actions/workflows/ci.yml/badge.svg)](https://github.com/Alexandru2984/ruby/actions/workflows/ci.yml)

A fast, self-hosted bookmark manager built with Ruby on Rails 8 and Hotwire.
Save a URL and the app does the rest: page title, description and favicon are
fetched in the background, everything is tagged, searchable and yours.

## Features

- **Accounts** — session-based authentication (Rails 8 authentication
  generator), sign-up, password reset by email, rate-limited auth endpoints.
- **Bookmarks** — per-user, validated and normalized URLs (`example.com`
  becomes `https://example.com`, non-HTTP schemes are rejected), duplicate
  protection per user backed by a unique index.
- **Automatic metadata** — a Solid Queue background job fills in the page
  title, description and favicon. Fetching is SSRF-hardened: private,
  loopback and link-local hosts are refused, redirects are re-validated hop
  by hop, and responses are time- and size-capped.
- **Tags** — comma-separated input, per-user namespace, one-click filtering,
  orphaned tags are pruned automatically.
- **Search & organization** — full-text-ish search across title/URL/
  description, favorites, soft archiving, visit tracking (click-throughs are
  counted atomically), four sort orders, pagination with Pagy.
- **Import & export** — import bookmarks HTML from Chrome/Firefox/Safari
  (tags, descriptions and original dates preserved, duplicates skipped);
  export everything as JSON, CSV or standard bookmarks HTML. Exports
  round-trip through the importer.
- **UI** — server-rendered Hotwire UI with Turbo Streams (favorite toggle),
  Stimulus (clipboard copy, dismissible flash), Tailwind CSS with automatic
  dark mode, contextual empty states.

## Stack

| Layer      | Choice                                                    |
| ---------- | --------------------------------------------------------- |
| Framework  | Ruby on Rails 8.1 (Ruby 3.3)                               |
| Database   | SQLite (WAL) — also backs cache, jobs and cable via Solid Cache/Queue/Cable |
| Frontend   | Hotwire (Turbo + Stimulus), Tailwind CSS 4, importmap — no Node build step |
| Web server | Puma (+ Thruster for HTTP caching/compression in containers) |
| Background | Solid Queue                                                |
| Testing    | Minitest: model, controller, job, service and system tests (Capybara + headless Chrome) |
| Quality    | RuboCop (rails-omakase), Brakeman, bundler-audit, importmap audit — all wired into GitHub Actions CI |

## Getting started

```bash
bin/setup            # installs gems, prepares the database, starts the app
```

or step by step:

```bash
bundle install
bin/rails db:prepare
bin/rails db:seed    # optional: demo user demo@example.com / password123
bin/dev              # server + Tailwind watcher (Procfile.dev)
```

## Tests & checks

```bash
bin/rails test          # unit + integration
bin/rails test:system   # browser tests (needs Chrome)
bin/rubocop             # style
bin/brakeman            # static security analysis
bin/bundler-audit       # known-vulnerable gems
bin/ci                  # everything CI runs
```

## Architecture notes

- `app/services/url_metadata.rb` — defensive HTTP client + HTML metadata
  parser used by `FetchBookmarkMetadataJob`. Never overwrites user-provided
  fields; retries transient network failures, gives up on permanent ones.
- `app/services/bookmark_import.rb` / `bookmark_export.rb` — the
  NETSCAPE-Bookmark-file-1 format in both directions; import is capped at
  1000 links and 5 MB per file and rate limited.
- `Bookmark#register_visit!` — visit counting is a single SQL `UPDATE … SET
  visits_count = visits_count + 1`, so concurrent clicks don't lose counts
  and `updated_at` stays meaningful.
- Tag names are normalized (`" Ruby  On Rails "` → `"ruby on rails"`) and
  unique per user; join rows carry a composite unique index.
- All bookmark queries go through `Current.user`, enforced by controller
  scoping and covered by cross-tenant tests (404 on other users' records).

## Deployment

The app is 12-factor-ish and containerizable (`Dockerfile` + Kamal config in
`config/deploy.yml`), but any way of running Puma works. A minimal systemd
setup:

```ini
[Service]
WorkingDirectory=/path/to/app
Environment=RAILS_ENV=production
Environment=SOLID_QUEUE_IN_PUMA=true   # run jobs inside Puma (single-server setup)
ExecStart=/path/to/app/bin/rails server
Restart=always
```

On each deploy:

```bash
bundle install
bin/rails db:migrate
bin/rails assets:precompile
systemctl restart <your-service>
```

`SOLID_QUEUE_IN_PUMA=true` makes Puma supervise Solid Queue (see
`config/puma.rb`), which is the simplest way to get background jobs —
metadata fetching — running on a single server. Split out `bin/jobs` onto a
dedicated process/host when load grows.

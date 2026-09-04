# Power Solutions Technical Test

Rails 8.1 application backed by SQLite.

## Front end

There is no Node.js toolchain and no bundler step:

* **Propshaft** serves the assets.
* **Import maps** (`config/importmap.rb`) load the JavaScript as ES modules
  straight from the gems, so `app/javascript/application.js` is the entry point.
* **dartsass-rails** compiles `app/assets/stylesheets/application.scss` into
  `app/assets/builds/application.css`.
* **Turbo** and **Stimulus** drive navigation and behaviour. jQuery is still
  loaded because cocoon (the dynamic nested question forms) depends on it.

Because Bootstrap's and jQuery's UMD builds register themselves on `window`,
the import order in `app/javascript/application.js` matters — jQuery before
cocoon, and Popper before Bootstrap.

## Requirements

* Ruby 3.4.9 (see `.ruby-version`)
* SQLite 3
* Docker (optional, for the containerized setup below)

## Running with Docker

The fastest way to get a working environment:

```bash
docker compose up --build
```

The app is then available at http://localhost:3000. The database is created and
migrated automatically on boot.

Other useful commands:

```bash
docker compose run --rm web ./bin/rails console
docker compose run --rm web ./bin/rails test
docker compose down
```

`compose.yaml` builds `Dockerfile.dev` and bind-mounts the working tree, so code
changes are picked up without rebuilding. Gems live in a named volume, so a
rebuild is only needed when the `Gemfile` changes.

## Running locally

```bash
bin/setup
bin/dev
```

## Tests

```bash
bin/rails db:test:prepare test test:system
```

Note that the suite is currently empty — there are no tests in `test/`.

## Deployment

Production images are built from `Dockerfile` (a separate, slimmer, multi-stage
build) and deployed with [Kamal](https://kamal-deploy.org):

```bash
bin/kamal deploy
```

Configure servers and registry credentials in `config/deploy.yml` before the
first deploy.

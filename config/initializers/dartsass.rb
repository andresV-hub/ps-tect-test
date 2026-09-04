# Be sure to restart your server when you modify this file.

# Bootstrap 5.3 still uses the legacy `@import` rule and legacy colour functions,
# which Dart Sass reports as deprecated. `--quiet-deps` silences those warnings
# for dependencies while keeping warnings from our own stylesheets visible.
Rails.application.config.dartsass.build_options += [ "--quiet-deps" ]

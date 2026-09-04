# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
Rails.application.config.assets.paths << Gem.loaded_specs["bootstrap-icons"].full_gem_path + "/assets/stylesheets"

# Sass sources are compiled by dartsass-rails into app/assets/builds, so Propshaft
# should not publish them as assets of their own (it would otherwise serve
# application.scss alongside the compiled application.css). dartsass-rails adds
# this directory to its own load path, so excluding it here does not affect it.
Rails.application.config.assets.excluded_paths << Rails.root.join("app/assets/stylesheets")

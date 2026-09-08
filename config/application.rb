require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module PiafApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Brazilian Portuguese as the default locale.
    config.i18n.default_locale = :"pt-BR"
    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "*.{rb,yml}").to_s]

    config.time_zone = "America/Fortaleza"
    config.active_record.default_timezone = :utc

    # Delayed Job is the background queue backend (delayed_job_active_record).
    config.active_job.queue_adapter = :delayed_job

    # Only exposes :id when inspecting records (keeps PII out of logs/console).
    config.active_record.attributes_for_inspect = %i[id]

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true
  end
end

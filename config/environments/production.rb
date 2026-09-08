require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true
  config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!).
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  config.cache_store = :memory_store

  # The queue backend is Delayed Job (see config/application.rb).
  # Remove the queue adapter if you import solid_queue back in the future.

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Set host to be used by links generated in mailer templates.
  config.action_mailer.default_url_options = {
    protocol: "https",
    host: ENV.fetch("PIAF_HOST", "piaf.ufrn.br")
  }

  # SMTP settings come from Rails credentials/config/env — never hardcode.
  config.action_mailer.smtp_settings = {
    address: ENV["SMTP_ADDRESS"] || Rails.application.credentials.dig(:smtp, :address),
    port: ENV["SMTP_PORT"].to_i.nonzero? || Rails.application.credentials.dig(:smtp, :port) || 587,
    user_name: ENV["SMTP_USERNAME"] || Rails.application.credentials.dig(:smtp, :user_name),
    password: ENV["SMTP_PASSWORD"] || Rails.application.credentials.dig(:smtp, :password),
    authentication: (ENV["SMTP_AUTHENTICATION"].presence || Rails.application.credentials.dig(:smtp, :authentication) || "plain").to_sym,
    enable_starttls_auto: true
  }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.raise_delivery_errors = ENV["PIAF_RAISE_DELIVERY_ERRORS"] == "true"

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Enable DNS rebinding protection and other `Host` header attacks.
  config.hosts = [
    ENV.fetch("PIAF_HOST", "piaf.ufrn.br")
  ]
end

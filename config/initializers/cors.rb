# Be sure to restart your server when you modify this file.

# Restrict CORS to the authorized frontend origins only. Origins come from
# Rails credentials (`allowed_origins`) or the PIAF_ALLOWED_ORIGINS env var
# (comma separated). Never use `origins "*"` when credentials are involved.

allowed_origins = ENV.fetch("PIAF_ALLOWED_ORIGINS", "").split(",").compact_blank
allowed_origins = Rails.application.credentials.dig(:allowed_origins) if allowed_origins.empty?
allowed_origins = [ "http://localhost:3001", "http://localhost:5173" ] if allowed_origins.blank?

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*allowed_origins)

    resource "*",
             headers: :any,
             methods: %i[get post put patch delete options head],
             max_age: 86_400,
             expose: %w[Authorization X-Page X-Per-Page X-Total X-Total-Pages X-Next-Page X-Prev-Page]
  end
end

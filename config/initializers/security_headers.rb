# frozen_string_literal: true

# Adds security-related response headers to every API response.
class SecurityHeaders
  HEADERS = {
    "X-Content-Type-Options" => "nosniff",
    "X-Frame-Options" => "DENY",
    "Referrer-Policy" => "no-referrer",
    "Permissions-Policy" => "camera=(), microphone=(), geolocation=()",
    "Cross-Origin-Resource-Policy" => "same-site",
    # Minimal CSP for an API returning only JSON (no inline script/style allowed).
    "Content-Security-Policy" => "default-src 'none'; frame-ancestors 'none'"
  }.freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)
    HEADERS.each { |key, value| headers[key] ||= value }
    [ status, headers, body ]
  end
end

Rails.application.config.middleware.use SecurityHeaders

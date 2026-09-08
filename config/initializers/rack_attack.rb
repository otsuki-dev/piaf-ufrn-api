# frozen_string_literal: true

# Rate limiting to mitigate brute-force and account-enumeration attacks on
# sensitive endpoints. Responds with 429 + Retry-After.

class Rack::Attack
  Rack::Attack.cache.store = Rails.cache if defined?(Rails) && Rails.cache

  # Login brute-force mitigation (per IP).
  throttle("logins/ip", limit: 10, period: 1.minute) do |request|
    request.ip if request.path.include?("/api/v1/auth/sign_in") && request.post?
  end

  # Account registration abuse mitigation (per IP).
  throttle("registrations/ip", limit: 5, period: 1.hour) do |request|
    request.ip if request.path.end_with?("/api/v1/auth") && request.post?
  end

  # Confirmation / password reset: prevents account enumeration via burst e-mail
  # sending (per IP).
  throttle("confirmations/ip", limit: 10, period: 1.hour) do |request|
    request.ip if request.path.include?("/api/v1/auth/confirmation")
  end

  throttle("passwords/ip", limit: 10, period: 1.hour) do |request|
    request.ip if request.path.include?("/api/v1/auth/password")
  end

  # Global protection for the registered API surface (per IP).
  throttle("api/ip", limit: 900, period: 1.minute) do |request|
    request.ip if request.path.start_with?("/api/")
  end

  # Emits an automatic "Retry-After" header based on the throttled period.
  self.throttled_response_retry_after_header = true

  self.throttled_responder = lambda do |_request|
    [
      429,
      { "Content-Type" => "application/json" },
      [ { errors: [ { status: 429, code: "rate_limited", title: I18n.t("errors.rate_limited") } ] }.to_json ]
    ]
  end
end

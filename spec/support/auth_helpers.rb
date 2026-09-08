# frozen_string_literal: true

# Helpers that exercise the JSON API the way a SPA would, including the JWT
# Bearer token obtained from the real sign-in endpoint.
module AuthHelpers
  def json_payload
    JSON.parse(response.body)
  end

  def api_post(path, payload = {}, headers = {})
    post path, params: payload.to_json, headers: json_headers(headers)
  end

  def api_put(path, payload = {}, headers = {})
    put path, params: payload.to_json, headers: json_headers(headers)
  end

  def api_patch(path, payload = {}, headers = {})
    patch path, params: payload.to_json, headers: json_headers(headers)
  end

  def api_get(path, params = {}, headers = {})
    get path, params: params, headers: json_headers(headers)
  end

  def api_delete(path, headers = {})
    delete path, params: nil, headers: json_headers(headers)
  end

  def sign_in_via_api(user, password: user.password)
    api_post "/api/v1/auth/sign_in", { user: { email: user.email, password: password } }
    expect(response).to have_http_status(:ok)
    { "Authorization" => "Bearer #{bearer_token}" }
  end

  def bearer_token
    response.headers["Authorization"].to_s.split(" ").last.presence ||
      json_payload.dig("meta", "token")
  end

  private

  def json_headers(headers)
    { "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json" }.merge(headers)
  end
end

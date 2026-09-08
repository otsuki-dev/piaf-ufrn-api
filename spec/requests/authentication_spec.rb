# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Authentication flow", type: :request do
  let(:valid_params) do
    {
      user: {
        username: "maria.silva",
        email: "maria.silva@example.com",
        password: "senhasegura123",
        password_confirmation: "senhasegura123",
        cpf: SpecSupport::Cpf.valid(900_000),
        birthdate: "1995-04-12",
        phone_number: "(84) 99999-0001",
        ufrn_student: true
      }
    }
  end

  describe "sign up" do
    it "creates an unconfirmed account and asks for email confirmation" do
      api_post "/api/v1/auth", valid_params

      expect(response).to have_http_status(:created)
      payload = json_payload
      expect(payload.dig("data", "username")).to eq("maria.silva")
      expect(payload.dig("data", "role")).to eq("student")
      expect(payload.dig("data", "masked_cpf")).to eq("***.***.***-#{valid_params.dig(:user, :cpf).last(2)}")
      expect(payload.dig("meta", "confirmation_required")).to eq(true)
      expect(payload.dig("data", "cpf")).to be_nil
      expect(User.last).not_to be_confirmed
    end

    it "rejects an invalid cpf" do
      api_post "/api/v1/auth", valid_params.deep_merge(user: { cpf: "12345678901" })

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_payload.dig("errors", 0, "source", "pointer")).to eq("/data/attributes/cpf")
    end

    it "rejects a short password" do
      api_post "/api/v1/auth", valid_params.deep_merge(user: { password: "123", password_confirmation: "123" })

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects duplicate cpf" do
      create(:user, cpf: valid_params.dig(:user, :cpf))
      api_post "/api/v1/auth", valid_params

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_payload["errors"].map { |e| e.dig("source", "pointer") })
        .to include("/data/attributes/cpf")
    end
  end

  describe "confirmation" do
    it "confirms the account with the emailed token" do
      api_post "/api/v1/auth", valid_params
      user = User.find_by(email: valid_params.dig(:user, :email))

      api_get "/api/v1/auth/confirmation", confirmation_token: user.confirmation_token

      expect(response).to have_http_status(:ok)
      expect(json_payload.dig("data", "confirmed")).to eq(true)
      expect(user.reload).to be_confirmed
    end
  end

  describe "sign in" do
    let!(:user) { create(:user, email: "login@example.com", password: "senhasegura123") }

    it "authenticates with valid credentials and returns the token" do
      api_post "/api/v1/auth/sign_in", { user: { email: user.email, password: "senhasegura123" } }

      expect(response).to have_http_status(:ok)
      expect(bearer_token).to be_present
      expect(response.headers["Authorization"]).to start_with("Bearer")
      expect(json_payload.dig("data", "email")).to eq(user.email)
    end

    it "rejects an unknown email" do
      api_post "/api/v1/auth/sign_in", { user: { email: "ghost@example.com", password: "senhasegura123" } }

      expect(response).to have_http_status(:unauthorized)
      expect(json_payload.dig("errors", 0, "code")).to eq("invalid_credentials")
    end

    it "rejects a wrong password" do
      api_post "/api/v1/auth/sign_in", { user: { email: user.email, password: "senhaerrada" } }

      expect(response).to have_http_status(:unauthorized)
      expect(json_payload.dig("errors", 0, "code")).to eq("invalid_credentials")
    end

    it "rejects unconfirmed accounts" do
      unconfirmed = create(:user, :unconfirmed, email: "pendente@example.com", password: "senhasegura123")
      api_post "/api/v1/auth/sign_in", { user: { email: unconfirmed.email, password: "senhasegura123" } }

      expect(response).to have_http_status(:unauthorized)
      expect(json_payload.dig("errors", 0, "code")).to eq("unconfirmed")
    end
  end

  describe "current user" do
    let!(:user) { create(:user, :instructor) }

    it "returns the profile of the authenticated user" do
      headers = sign_in_via_api(user)

      api_get "/api/v1/me", {}, headers

      expect(response).to have_http_status(:ok)
      expect(json_payload.dig("data", "username")).to eq(user.username)
      expect(json_payload.dig("data", "role")).to eq("instructor")
      expect(json_payload.dig("data", "cpf")).to be_nil
    end

    it "rejects requests without a token" do
      api_get "/api/v1/me"

      expect(response).to have_http_status(:unauthorized)
      expect(json_payload.dig("errors", 0, "code")).to eq("unauthorized")
    end

    it "rejects an invalid token" do
      api_get "/api/v1/me", {}, { "Authorization" => "Bearer tokensobo" }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "sign out" do
    it "revokes the token so it can no longer be used" do
      user = create(:user)
      headers = sign_in_via_api(user)

      api_delete "/api/v1/auth/sign_out", headers
      expect(response).to have_http_status(:no_content)

      api_get "/api/v1/me", {}, headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "password reset" do
    let!(:user) { create(:user, email: "reset@example.com") }

    it "sends instructions without leaking the account existence" do
      api_post "/api/v1/auth/password", { user: { email: "nao-existe@example.com" } }
      expect(response).to have_http_status(:ok)
    end

    it "resets the password with a valid token" do
      api_post "/api/v1/auth/password", { user: { email: user.email } }
      expect(response).to have_http_status(:ok)

      raw_token = ActionMailer::Base.deliveries.last.text_part.decoded[/reset_password_token=([^&\s]+)/, 1]
      expect(raw_token).to be_present

      api_put "/api/v1/auth/password", {
        user: {
          reset_password_token: raw_token,
          password: "novasenha456",
          password_confirmation: "novasenha456"
        }
      }

      expect(response).to have_http_status(:ok)
      headers = sign_in_via_api(user, password: "novasenha456")
      api_get "/api/v1/me", {}, headers
      expect(response).to have_http_status(:ok)
    end
  end
end

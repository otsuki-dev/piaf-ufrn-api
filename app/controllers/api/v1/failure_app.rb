# frozen_string_literal: true

module Api
  module V1
    # JSON failure app used by Warden/Devise when authentication fails, so the
    # API always answers with a consistent JSON error payload.
    class FailureApp < Devise::FailureApp
      def respond
        self.status = 401
        self.content_type = "application/json; charset=utf-8"
        self.response_body = error_payload
      end

      private

      def error_payload
        payload = {
          errors: [ {
            status: 401,
            code: failure_code,
            title: failure_title,
            detail: failure_message
          } ]
        }
        payload.to_json
      end

      def failure_code
        return "unconfirmed" if unconfirmed_account_locked?
        return "invalid_credentials" if params["scope"].blank? && invalid_credentials?

        "unauthorized"
      end

      def failure_title
        case failure_code
        when "unconfirmed" then I18n.t("errors.unconfirmed")
        when "invalid_credentials" then I18n.t("errors.invalid_credentials")
        else I18n.t("errors.unauthenticated")
        end
      end

      def failure_message
        return I18n.t("devise.failure.unconfirmed") if unconfirmed_account_locked?

        i18n_message.presence || I18n.t("errors.unauthenticated")
      end

      def unconfirmed_account_locked?
        email = params.dig("user", "email").presence
        return false unless email

        user = User.find_by(email: email.to_s.downcase)
        user.present? && user.confirmed_at.blank?
      rescue ActiveRecord::QueryCanceled, StandardError
        false
      end

      def invalid_credentials?
        invalid_messages = [
          I18n.t("devise.failure.invalid"),
          I18n.t("devise.failure.not_found_in_database")
        ]
        invalid_messages.include?(i18n_message.to_s)
      rescue StandardError
        false
      end
    end
  end
end

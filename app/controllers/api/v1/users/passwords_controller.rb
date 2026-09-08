# frozen_string_literal: true

module Api
  module V1
    module Users
      class PasswordsController < Devise::PasswordsController
        include Api::V1::Renderable

        # POST /api/v1/auth/password { user: { email } }
        def create
          self.resource = resource_class.send_reset_password_instructions(resource_params)
          render json: { data: { message: I18n.t("devise.passwords.send_instructions") } }, status: :ok
        end

        # PUT /api/v1/auth/password { user: { reset_password_token, password, password_confirmation } }
        def update
          self.resource = resource_class.reset_password_by_token(resource_params)
          if resource.errors.empty?
            render json: { data: { message: I18n.t("devise.passwords.updated_not_active") } }, status: :ok
          else
            render_validation_errors(resource)
          end
        end

        private

        def resource_params
          params.require(:user).permit(:email, :reset_password_token, :password, :password_confirmation)
        end
      end
    end
  end
end

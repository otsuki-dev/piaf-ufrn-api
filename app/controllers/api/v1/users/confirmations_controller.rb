# frozen_string_literal: true

module Api
  module V1
    module Users
      class ConfirmationsController < Devise::ConfirmationsController
        include Api::V1::Renderable

        before_action :authenticate_user!, only: []

        def create
          self.resource = resource_class.send_confirmation_instructions(resource_params)
          if successfully_sent?(resource)
            render json: {
              data: { message: I18n.t("devise.confirmations.send_instructions") }
            }, status: :ok
          else
            render_validation_errors(resource)
          end
        end

        # GET /api/v1/auth/confirmation?confirmation_token=TOKEN
        def show
          self.resource = resource_class.confirm_by_token(params[:confirmation_token])
          if resource.errors.empty?
            render json: { data: { confirmed: true, message: I18n.t("devise.confirmations.confirmed") } },
                   status: :ok
          else
            render_validation_errors(resource)
          end
        end

        protected

        def after_confirmation_path_for(_resource_name, _resource)
          "/"
        end

        private

        def resource_params
          params.require(:user).permit(:email, :confirmation_token)
        end
      end
    end
  end
end

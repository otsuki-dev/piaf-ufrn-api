# frozen_string_literal: true

module Api
  module V1
    module Users
      class RegistrationsController < Devise::RegistrationsController
        include Api::V1::Renderable

        def create
          build_resource(sign_up_params)
          resource.save
          if resource.persisted?
            render_registered
          else
            render_validation_errors(resource)
          end
        end

        def update
          self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
          if update_resource(resource, account_update_params)
            render_serialized(resource, serializer: UserSerializer, view: :me)
          else
            render_validation_errors(resource)
          end
        end

        def destroy
          if resource.destroy
            head :no_content
          else
            render_validation_errors(resource)
          end
        end

        private

        def render_registered
          confirmed = resource.confirmed?
          meta = {}
          if confirmed
            token = request.env["warden-jwt_auth.token"]
            meta[:token] = token if token.present?
          else
            meta[:confirmation_required] = true
          end

          render_serialized(resource, serializer: UserSerializer, view: :me,
                                       status: :created, meta: meta)
        end

        def sign_up_params
          params.require(:user).permit(
            :username, :email, :password, :password_confirmation,
            :cpf, :birthdate, :phone_number, :ufrn_student,
            :ufrn_registration_number, :rg_user, :address, :cep, :district
          )
        end

        def account_update_params
          params.require(:user).permit(
            :username, :email, :password, :password_confirmation, :current_password,
            :phone_number, :ufrn_student, :ufrn_registration_number,
            :rg_user, :address, :cep, :district
          )
        end
      end
    end
  end
end

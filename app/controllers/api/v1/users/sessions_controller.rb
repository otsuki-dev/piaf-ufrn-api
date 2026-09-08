# frozen_string_literal: true

module Api
  module V1
    module Users
      class SessionsController < Devise::SessionsController
        include Api::V1::Renderable

        skip_before_action :verify_signed_out_user, only: :destroy
        before_action :authenticate_user!, only: :destroy

        def create
          self.resource = warden.authenticate!(auth_options)
          sign_in(resource_name, resource)
          render_signed_in
        end

        def destroy
          sign_out(resource_name)
          head :no_content
        end

        private

        def render_signed_in
          meta = {}
          token = request.env["warden-jwt_auth.token"]
          meta[:token] = token if token.present?

          render_serialized(resource, serializer: UserSerializer, view: :me, meta: meta)
        end
      end
    end
  end
end

# frozen_string_literal: true

module Api
  module V1
    class UsersController < Api::V1::BaseController
      def me
        render_serialized(current_user, serializer: UserSerializer, view: :me)
      end
    end
  end
end

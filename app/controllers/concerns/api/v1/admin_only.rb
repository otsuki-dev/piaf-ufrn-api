# frozen_string_literal: true

module Api::V1::AdminOnly
  extend ActiveSupport::Concern

  included do
    before_action :require_admin!
  end

  private

  def require_admin!
    return if current_user&.admin?

    raise Pundit::NotAuthorizedError
  end
end

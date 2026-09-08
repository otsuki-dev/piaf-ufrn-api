# frozen_string_literal: true

module Api::V1::Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
    before_action :set_paper_trail_actor
  end
end

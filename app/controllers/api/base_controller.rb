# frozen_string_literal: true

module Api
  class BaseController < ApplicationController
    include Pundit::Authorization
    include Pagy::Backend
    include Api::V1::ErrorHandling
    include Api::V1::Renderable
    include Api::V1::Paginatable

    private

    def set_paper_trail_actor
      PaperTrail.request.whodunnit = current_user&.id.to_s
    end
  end
end

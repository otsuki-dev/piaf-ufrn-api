# frozen_string_literal: true

module Api
  module V1
    class BaseController < Api::BaseController
      include Api::V1::Authenticatable
    end
  end
end

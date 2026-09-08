# frozen_string_literal: true

module Api::V1::ErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError, with: :internal_server_error
    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
    rescue_from ActiveRecord::RecordNotUnique, with: :record_not_unique
    rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
    rescue_from Pundit::NotAuthorizedError, with: :not_authorized
    rescue_from ActionController::ParameterMissing, with: :parameter_missing
    rescue_from ActionController::UnpermittedParameters, with: :unpermitted_parameters
    rescue_from JWT::ExpiredSignature, with: :expired_token_error
    rescue_from JWT::DecodeError, JWT::VerificationError, with: :invalid_token_error

    before_action :log_request_signature
  end

  private

  def record_not_found(exception = nil)
    render_error :not_found, code: "not_found", title: I18n.t("errors.record_not_found")
  end

  def record_not_unique
    render_error :unprocessable_content,
                 code: "record_not_unique",
                 title: I18n.t("errors.record_not_unique")
  end

  def record_invalid(exception)
    render_validation_errors(exception.record)
  end

  def not_authorized
    render_error :forbidden, code: "forbidden", title: I18n.t("errors.forbidden")
  end

  def parameter_missing(exception)
    render_error :bad_request,
                 code: "missing_parameter",
                 title: I18n.t("errors.missing_parameter", param: exception.param)
  end

  def unpermitted_parameters(exception)
    render_error :unprocessable_content,
                 code: "unpermitted_parameters",
                 title: I18n.t("errors.unpermitted_parameters", params: exception.params.join(", "))
  end

  def expired_token_error
    render_error :unauthorized, code: "token_expired", title: I18n.t("errors.token_expired")
  end

  def invalid_token_error
    render_error :unauthorized, code: "token_invalid", title: I18n.t("errors.token_invalid")
  end

  def internal_server_error(exception)
    logger.error "[#{self.class}] #{exception.class}: #{exception.message}"
    logger.error exception.backtrace.join("\n") if exception.backtrace

    Rails.error.report(exception)

    render_error :internal_server_error, code: "internal_error", title: I18n.t("errors.internal_error")
  end

  def log_request_signature
    return unless Rails.logger.info?

    logger.info "request[#{self.class}##{action_name}] params=#{params.except(:action, :controller).inspect}"
  end
end

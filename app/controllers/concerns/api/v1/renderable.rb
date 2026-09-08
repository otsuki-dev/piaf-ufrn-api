# frozen_string_literal: true

module Api::V1::Renderable
  extend ActiveSupport::Concern

  protected

  def unwrap_serialized(rendered)
    rendered.is_a?(String) ? ActiveSupport::JSON.decode(rendered) : rendered
  end

  def render_serialized(resource, serializer:, status: :ok, view: nil, meta: {})
    payload = { data: unwrap_serialized(serializer.render(resource, view: view)) }
    payload[:meta] = meta if meta.present?
    render json: payload, status: status
  end

  def render_collection(serializer:, records:, view: nil, meta: {})
    payload = { data: unwrap_serialized(serializer.render(records, view: view)) }
    payload[:meta] = meta if meta.present?
    render json: payload
  end

  def render_error(status, code:, title:, detail: nil, source: nil)
    error = { status: Rack::Utils.status_code(status), code: code, title: title }
    error[:detail] = detail if detail.present?
    error[:source] = source if source.present?
    render json: { errors: [ error ] }, status: status
  end

  def render_validation_errors(record)
    errors = record.errors.map do |error|
      {
        status: Rack::Utils.status_code(:unprocessable_content),
        code: "validation_failed",
        title: error.message,
        source: { pointer: "/data/attributes/#{error.attribute}" }
      }
    end
    render json: { errors: errors }, status: :unprocessable_content
  end
end

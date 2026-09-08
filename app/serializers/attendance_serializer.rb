# frozen_string_literal: true

class AttendanceSerializer < Blueprinter::Base
  identifier :id

  fields :date, :present, :created_at, :updated_at

  association :enrollment, blueprint: EnrollmentSerializer, view: :detail
end

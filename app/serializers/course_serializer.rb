# frozen_string_literal: true

class CourseSerializer < Blueprinter::Base
  identifier :id

  fields :modality, :modality_label, :custom_modality, :class_time,
         :start_date, :end_date, :slots, :status

  field :available_slots

  association :user, blueprint: UserSerializer, view: :default

  view :detail do
    fields :created_at, :updated_at

    field :enrollments_count do |course, _options|
      course.enrollments.count
    end

    field :confirmed_count do |course, _options|
      course.enrollments.confirmed.count
    end

    field :waiting_count do |course, _options|
      course.enrollments.waitlisted.count
    end

    field :attended_classes do |course, _options|
      course.attendances.present.count
    end
  end
end

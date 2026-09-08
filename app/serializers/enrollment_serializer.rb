# frozen_string_literal: true

class EnrollmentSerializer < Blueprinter::Base
  identifier :id

  fields :status, :terms_accepted, :renewed_from_enrollment_id, :created_at, :updated_at

  association :user, blueprint: UserSerializer
  association :course, blueprint: CourseSerializer

  # Anamnesis answers are sensitive health data (LGPD) and appear only in the
  # detailed view, reachable solely by the owner, admins or the instructor.
  view :detail do
    fields :heart_problem, :chest_pain, :recent_chest_pain, :dizziness,
           :bone_problem, :blood_pressure_meds, :other_reasons,
           :physical_activity_responsibility

    field :attendance_rate

    field :attendance_count do |enrollment, _options|
      enrollment.attendances.count
    end

    field :present_count do |enrollment, _options|
      enrollment.attendances.present.count
    end
  end
end

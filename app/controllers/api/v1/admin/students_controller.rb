# frozen_string_literal: true

module Api
  module V1
    module Admin
      class StudentsController < Api::V1::BaseController
        include Api::V1::AdminOnly

        # POST /api/v1/admin/students/:id/deactivate
        #
        # Explicitly deactivates every active enrollment of a student, freeing
        # slots and automatically promoting the course waitlists.
        def deactivate
          student = User.find(params[:id])
          affected = Enrollment.transaction do
            student.enrollments.where(status: :confirmed).count.tap do
              student.enrollments.where(status: :confirmed).find_each(&:deactivate!)
            end
          end

          render json: { data: { student_id: student.id, deactivated_count: affected } }, status: :ok
        end
      end
    end
  end
end

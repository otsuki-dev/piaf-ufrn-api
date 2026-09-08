# frozen_string_literal: true

module Api
  module V1
    module Admin
      class StatsController < Api::V1::BaseController
        include Api::V1::AdminOnly

        # GET /api/v1/admin/stats
        def index
          render json: { data: stats }
        end

        private

        def stats
          enrollments = Enrollment.all
          by_status = enrollments.group(:status).count
          courses = Course.all

          {
            users: {
              total: User.count,
              admins: User.admins.count,
              instructors: User.instructors.count,
              students: User.students.count,
              confirmed: User.confirmed_accounts.count
            },
            courses: {
              total: courses.count,
              active: courses.active.count,
              by_modality: courses.group(:modality).count
            },
            enrollments: {
              total: enrollments.count,
              by_status: by_status,
              waitlist: by_status["waitlisted"].to_i,
              confirmed: by_status["confirmed"].to_i
            },
            attendance: {
              registered_today: Attendance.present.where(date: Date.current).count,
              registered_this_week: Attendance.where(date: Date.current.all_week).count
            }
          }
        end
      end
    end
  end
end

# frozen_string_literal: true

module Api
  module V1
    module Admin
      class ReportsController < Api::V1::BaseController
        include Api::V1::AdminOnly

        # GET /api/v1/admin/reports
        def index
          render json: { data: build_report }
        end

        private

        def build_report
          per_course = Course.includes(:enrollments).ordered_by_recent.map do |course|
            enrollments = course.enrollments
            group = enrollments.group(:status).count
            total = enrollments.count
            present = course.attendances.present.count
            attendances = course.attendances.count

            {
              course_id: course.id,
              modality: course.modality_label,
              class_time: course.class_time,
              status: course.status,
              slots: course.slots,
              occupation_rate: occupation_rate(course),
              confirmed: group["confirmed"].to_i,
              waitlisted: group["waitlisted"].to_i,
              pending: group["pending"].to_i,
              cancelled: group["cancelled"].to_i,
              inactive: group["inactive"].to_i,
              total_enrollments: total,
              evasion_rate: evasion_rate(total, group),
              attendance_rate: attendance_rate(present, attendances)
            }
          end

          {
            courses: per_course,
            summary: report_summary(per_course)
          }
        end

        def occupation_rate(course)
          return 0 if course.slots.to_i.zero?

          (100.0 * course.enrollments.confirmed.count / course.slots).round(1)
        end

        def evasion_rate(total, group)
          return 0 if total.zero?

          (100.0 * (group["cancelled"].to_i + group["inactive"].to_i) / total).round(1)
        end

        def attendance_rate(present, attendances)
          return 0 if attendances.zero?

          (100.0 * present / attendances).round(1)
        end

        def report_summary(courses)
          averages = courses.reduce([]) { |acc, c| acc + [ c[:occupation_rate] ] }
          evasions = courses.reduce([]) { |acc, c| acc + [ c[:evasion_rate] ] }

          {
            total_courses: courses.size,
            active_courses: courses.count { |c| c[:status] == :open },
            avg_occupation_rate: (averages.sum / averages.size.to_f).round(1),
            avg_evasion_rate: (evasions.sum / evasions.size.to_f).round(1),
            total_enrollments: courses.sum { |c| c[:total_enrollments] }
          }
        end
      end
    end
  end
end

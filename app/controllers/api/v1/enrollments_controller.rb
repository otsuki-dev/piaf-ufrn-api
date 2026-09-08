# frozen_string_literal: true

module Api
  module V1
    class EnrollmentsController < Api::V1::BaseController
      before_action :set_enrollment, only: %i[show renew destroy attendance]

      # GET /api/v1/enrollments
      def index
        scope = policy_scope(Enrollment).recently_created
        scope = scope.for_course(params[:course_id]) if params[:course_id]
        scope = scope.where(status: params[:status]) if params[:status].in?(Enrollment.statuses.keys)

        records, pagy = pagy_collection(scope)
        render_collection serializer: EnrollmentSerializer, records: records,
                          view: :default, meta: pagy_meta(pagy)
      end

      # GET /api/v1/enrollments/:id
      def show
        authorize @enrollment
        render_serialized(@enrollment, serializer: EnrollmentSerializer, view: :detail)
      end

      # POST /api/v1/enrollments
      def create
        course = Course.find(params[:course_id])
        authorize Enrollment.new(user: current_user, course: course)
        enrollment = Enrollment.enroll!(user: current_user, course: course,
                                        attributes: enrollment_params)
        render_serialized(enrollment, serializer: EnrollmentSerializer,
                                      view: :detail, status: :created)
      end

      # POST /api/v1/enrollments/:id/renew
      def renew
        authorize @enrollment, :renew?
        target_course = Course.find(params[:course_id].presence || @enrollment.course_id)
        renewal = @enrollment.renew!(course: target_course, attributes: enrollment_params)
        render_serialized(renewal, serializer: EnrollmentSerializer,
                                    view: :detail, status: :created)
      end

      # DELETE /api/v1/enrollments/:id
      def destroy
        authorize @enrollment
        @enrollment.cancel!
        head :no_content
      end

      # POST /api/v1/enrollments/:id/attendance  { date:, present: }
      def attendance
        authorize @enrollment, :attendance?
        date = Date.parse(params[:date].to_s)
        present = params[:present].nil? ? true : ActiveModel::Type::Boolean.new.cast(params[:present])
        attendance = @enrollment.mark_attendance!(date: date, present: present)
        render_serialized(attendance, serializer: AttendanceSerializer)
      rescue ArgumentError
        render_error :unprocessable_content, code: "invalid_date", title: I18n.t("errors.invalid_date")
      end

      private

      def set_enrollment
        @enrollment = Enrollment.find(params[:id])
      end

      def enrollment_params
        params.permit(*Enrollment::ANAMNESIS_ATTRIBUTES)
      end
    end
  end
end

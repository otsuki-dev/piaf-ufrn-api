# frozen_string_literal: true

module Api
  module V1
    class CoursesController < Api::V1::BaseController
      before_action :set_course, only: %i[show update destroy]
      skip_before_action :authenticate_user!, only: %i[index show]

      # GET /api/v1/courses
      def index
        scope = Course.upcoming.by_modality(params[:modality])
        records, pagy = pagy_collection(scope)

        render_collection serializer: CourseSerializer, records: records,
                          view: :default, meta: pagy_meta(pagy)
      end

      # GET /api/v1/courses/:id
      def show
        authorize @course
        render_serialized(@course, serializer: CourseSerializer, view: :detail)
      end

      # POST /api/v1/courses
      def create
        authorize Course.new(user: current_user)
        @course = Course.new(course_params)
        @course.user ||= current_user if current_user.instructor? || current_user.admin?
        if @course.save
          render_serialized(@course, serializer: CourseSerializer, view: :detail, status: :created)
        else
          render_validation_errors(@course)
        end
      end

      # PATCH /api/v1/courses/:id
      def update
        authorize @course
        if @course.update(course_params)
          render_serialized(@course, serializer: CourseSerializer, view: :detail)
        else
          render_validation_errors(@course)
        end
      end

      # DELETE /api/v1/courses/:id
      def destroy
        authorize @course
        if @course.enrollments.any?
          render_error :conflict, code: "course_has_enrollments",
                                 title: I18n.t("errors.course_has_enrollments")
          return
        end

        @course.destroy
        head :no_content
      end

      private

      def set_course
        @course = Course.find(params[:id])
      end

      def course_params
        params.require(:course).permit(*CoursePolicy.new(current_user, @course).permitted_attributes)
      end
    end
  end
end

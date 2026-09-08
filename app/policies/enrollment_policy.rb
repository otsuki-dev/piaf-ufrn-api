# frozen_string_literal: true

class EnrollmentPolicy < ApplicationPolicy
  def create?
    user.present?
  end

  def show?
    user.present? && (user.id == record.user_id || admin? || course_instructor?)
  end

  def update?
    user.present? && (admin? || course_instructor?)
  end

  def destroy?
    user.present? && (user.id == record.user_id || admin? || course_instructor?)
  end

  def renew?
    user.present? && user.id == record.user_id
  end

  def attendance?
    user.present? && (admin? || course_instructor?)
  end

  alias_method :mark_attendance?, :attendance?

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user&.admin?

      if user&.instructor?
        scope.joins(:course).where(courses: { user_id: user.id })
      else
        scope.where(user_id: user.id)
      end
    end
  end

  private

  def course_instructor?
    record.respond_to?(:course) && record.course&.user_id.present? && record.course.user_id == user.id
  end
end

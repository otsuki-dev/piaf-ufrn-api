# frozen_string_literal: true

class CoursePolicy < ApplicationPolicy
  # Catalog lookup is public.
  def index?
    true
  end

  def show?
    true
  end

  def create?
    return false if user.blank?

    admin? || instructor?
  end

  def update?
    return false if user.blank?

    admin? || teacher?
  end

  def destroy?
    return false if user.blank?

    admin? || teacher?
  end

  def manage_attendances?
    return false if user.blank?

    admin? || teacher?
  end

  alias_method :attendance?, :manage_attendances?

  def permitted_attributes
    %i[
      start_date end_date class_time slots modality custom_modality user_id
    ]
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user&.admin?

      if user&.instructor?
        scope.where(user_id: user.id).or(scope.where(user_id: nil))
      else
        scope.all
      end
    end
  end

  private

  def teacher?
    instructor? && record.respond_to?(:user_id) && (record.user_id == user.id || record.user_id.nil?)
  end
end

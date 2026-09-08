# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope
    end
  end

  private

  def admin?
    user.present? && user.admin?
  end

  def instructor?
    user.present? && user.instructor?
  end

  def owns_record?
    user.present? && record.respond_to?(:user_id) && record.user_id == user.id
  end
end

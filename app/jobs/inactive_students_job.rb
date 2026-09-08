# frozen_string_literal: true

class InactiveStudentsJob < ApplicationJob
  queue_as :maintenance

  def perform(since: 2.weeks.ago)
    Enrollment.deactivate_inactive_students!(since: since)
  end
end

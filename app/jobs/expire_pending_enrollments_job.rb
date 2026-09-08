# frozen_string_literal: true

class ExpirePendingEnrollmentsJob < ApplicationJob
  queue_as :maintenance

  def perform(expired_before: 7.days.ago)
    Enrollment.expire_pending!(expired_before: expired_before)
  end
end

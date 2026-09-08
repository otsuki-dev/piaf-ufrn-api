# frozen_string_literal: true

# Nightly maintenance: removes expired JWT entries from the denylist so the
# table does not grow forever.
class DailyMaintenanceJob < ApplicationJob
  queue_as :maintenance

  def perform
    JwtDenylist.where(exp: ...Time.current).in_batches.delete_all
  end
end

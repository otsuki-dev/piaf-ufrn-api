# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Scheduled jobs", type: :job do
  describe ExpirePendingEnrollmentsJob do
    it "cancels stale pending enrollments" do
      stale = create(:enrollment, :pending, created_at: 8.days.ago)
      described_class.perform_now

      expect(stale.reload).to be_cancelled
    end
  end

  describe InactiveStudentsJob do
    it "deactivates confirmed no-shows" do
      course = create(:course, slots: 5)
      no_show = create(:enrollment, course: course)

      described_class.perform_now

      expect(no_show.reload).to be_inactive
    end
  end

  describe DailyMaintenanceJob do
    it "purges expired jwt denylist entries" do
      expired = JwtDenylist.create!(jti: "expired-jti", exp: 1.hour.ago)
      valid = JwtDenylist.create!(jti: "valid-jti", exp: 1.day.from_now)

      described_class.perform_now

      expect(JwtDenylist.exists?(expired.id)).to be(false)
      expect(JwtDenylist.exists?(valid.id)).to be(true)
    end
  end
end

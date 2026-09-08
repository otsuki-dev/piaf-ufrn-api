# frozen_string_literal: true

require "rails_helper"

RSpec.describe Attendance, type: :model do
  subject(:attendance) { build(:attendance) }

  describe "validations" do
    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:date) }
    it { is_expected.to validate_uniqueness_of(:date).scoped_to(:enrollment_id) }

    it "rejects attendance before the course starts" do
      attendance.date = attendance.enrollment.course.start_date - 1.day
      expect(attendance).not_to be_valid
      expect(attendance.errors[:date]).to be_present
    end

    it "rejects attendance after the course ends" do
      attendance.date = attendance.enrollment.course.end_date + 1.day
      expect(attendance).not_to be_valid
      expect(attendance.errors[:date]).to be_present
    end
  end

  describe ".record_for" do
    let(:enrollment) { create(:enrollment) }
    let(:course_start) { enrollment.course.start_date.to_date }

    it "creates a new record" do
      expect {
        described_class.record_for(enrollment: enrollment, date: course_start, present: true)
      }.to change(described_class, :count).by(1)
    end

    it "is idempotent for the same date" do
      described_class.record_for(enrollment: enrollment, date: course_start, present: true)

      expect {
        described_class.record_for(enrollment: enrollment, date: course_start, present: false)
      }.not_to change(described_class, :count)
      expect(enrollment.attendances.last.present).to be(false)
    end

    it "raises on dates outside the course period" do
      expect {
        described_class.record_for(enrollment: enrollment, date: course_start - 5.days, present: true)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "scopes" do
    let(:enrollment) { create(:enrollment) }
    let(:course_start) { enrollment.course.start_date.to_date }

    before do
      create(:attendance, enrollment: enrollment, date: course_start, present: true)
      create(:attendance, :absent, enrollment: enrollment, date: course_start + 1.day)
    end

    it { expect(described_class.present.count).to eq(1) }
    it { expect(described_class.absent.count).to eq(1) }
    it { expect(described_class.ordered.first.date).to eq(course_start) }
  end
end

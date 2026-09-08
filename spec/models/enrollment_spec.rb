# frozen_string_literal: true

require "rails_helper"

RSpec.describe Enrollment, type: :model do
  subject(:enrollment) { build(:enrollment) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires terms acceptance" do
      enrollment.terms_accepted = false
      expect(enrollment).not_to be_valid
      expect(enrollment.errors[:terms_accepted]).to be_present
    end

    it "downcases an uppercase status" do
      enrollment.status = "CONFIRMED"
      enrollment.validate
      expect(enrollment.status).to eq("confirmed")
    end

    it "rejects unknown statuses" do
      enrollment.status = "nova"
      expect(enrollment).not_to be_valid
      expect(enrollment.errors[:status]).to be_present
    end
  end

  describe ".enroll!" do
    it "creates a confirmed enrollment while slots are available" do
      course = create(:course, slots: 10)
      result = described_class.enroll!(user: create(:user), course: course, attributes: { terms_accepted: true })

      expect(result).to be_confirmed
      expect(course.available_slots).to eq(9)
    end

    it "queues a confirmation email" do
      course = create(:course, slots: 10)
      expect { described_class.enroll!(user: create(:user), course: course, attributes: { terms_accepted: true }) }
        .to change(enqueued_jobs, :size).by(1)
    end

    it "sends the student to the waitlist when the course is full" do
      course = create(:course, slots: 1)
      create(:enrollment, course: course)

      waitlisted = described_class.enroll!(user: create(:user), course: course, attributes: { terms_accepted: true })

      expect(waitlisted).to be_waitlisted
    end

    it "raises when a user already has an active enrollment in the course" do
      course = create(:course, slots: 10)
      user = create(:user)
      described_class.enroll!(user: user, course: course, attributes: { terms_accepted: true })

      expect {
        described_class.enroll!(user: user, course: course, attributes: { terms_accepted: true })
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "allows re-enrollment after cancelling" do
      course = create(:course, slots: 10)
      user = create(:user)
      first = described_class.enroll!(user: user, course: course, attributes: { terms_accepted: true })
      first.cancel!

      second = described_class.enroll!(user: user, course: course, attributes: { terms_accepted: true })
      expect(second).to be_confirmed
    end
  end

  describe "#renew!" do
    it "copies the anamnesis and links the previous enrollment" do
      course = create(:course, slots: 10)
      renewal_target = create(:course, slots: 10)
      user = create(:user)
      enrollment = described_class.enroll!(
        user: user, course: course,
        attributes: { terms_accepted: true, heart_problem: false, other_reasons: true }
      )

      renewal = enrollment.renew!(course: renewal_target)

      expect(renewal).to be_confirmed
      expect(renewal.renewed_from_enrollment_id).to eq(enrollment.id)
      expect(renewal.heart_problem).to eq(false)
      expect(renewal.other_reasons).to eq(true)
      expect(renewal.terms_accepted).to eq(true)
    end
  end

  describe "#cancel!" do
    it "cancels the enrollment" do
      enrollment = create(:enrollment)
      enrollment.cancel!
      expect(enrollment).to be_cancelled
    end

    it "frees the slot" do
      course = create(:course, slots: 1)
      enrollment = create(:enrollment, course: course)
      expect { enrollment.cancel! }.to change { course.reload.available_slots }.by(1)
    end

    it "promotes the first waitlisted student" do
      course = create(:course, slots: 1)
      confirmed = create(:enrollment, course: course)
      waitlisted = create(:enrollment, :waitlisted, course: course)

      expect { confirmed.cancel! }.to change { waitlisted.reload.status }.to("confirmed")
    end

    it "enqueues the cancellation and promotion emails" do
      course = create(:course, slots: 1)
      confirmed = create(:enrollment, course: course)
      create(:enrollment, :waitlisted, course: course)

      expect { confirmed.cancel! }.to change(enqueued_jobs, :size).by(2)
    end
  end

  describe "#deactivate!" do
    it "deactivates the enrollment and frees the slot" do
      course = create(:course, slots: 1)
      enrollment = create(:enrollment, course: course)
      expect { enrollment.deactivate! }.to change { course.reload.available_slots }.by(1)
      expect(enrollment).to be_inactive
    end
  end

  describe ".expire_pending!" do
    it "cancels stale pending enrollments" do
      stale = create(:enrollment, :pending, created_at: 8.days.ago)
      fresh = create(:enrollment, :pending, created_at: 1.hour.ago)

      described_class.expire_pending!

      expect(stale.reload).to be_cancelled
      expect(fresh.reload).to be_pending
    end
  end

  describe ".deactivate_inactive_students!" do
    it "deactivates confirmed no-show students and promotes the waitlist" do
      course = create(:course, slots: 1)
      no_show = create(:enrollment, course: course)
      waitlisted = create(:enrollment, :waitlisted, course: course)

      described_class.deactivate_inactive_students!(since: 2.weeks.ago)

      expect(no_show.reload).to be_inactive
      expect(waitlisted.reload).to be_confirmed
    end

    it "keeps students who attended recently" do
      course = create(:course, slots: 10, start_date: 1.month.ago.to_date)
      active = create(:enrollment, course: course)
      create(:attendance, enrollment: active, date: 1.day.ago.to_date)

      described_class.deactivate_inactive_students!(since: 2.weeks.ago)

      expect(active.reload).to be_confirmed
    end
  end

  describe "#mark_attendance!" do
    let(:course) { create(:course, slots: 10) }
    let(:enrollment) { create(:enrollment, course: course) }

    it "records a present attendance" do
      attendance = enrollment.mark_attendance!(date: course.start_date, present: true)
      expect(attendance).to be_persisted
      expect(attendance).to be_present
    end

    it "updates an existing record instead of duplicating" do
      enrollment.mark_attendance!(date: course.start_date, present: true)
      expect {
        enrollment.mark_attendance!(date: course.start_date, present: false)
      }.not_to change(Attendance, :count)
      expect(enrollment.attendances.last.present).to be(false)
    end
  end

  describe "#attendance_rate" do
    it "returns the percentage of present classes" do
      course = create(:course, slots: 10)
      enrollment = create(:enrollment, course: course)
      enrollment.mark_attendance!(date: course.start_date, present: true)
      enrollment.mark_attendance!(date: course.start_date + 1.day, present: false)

      expect(enrollment.attendance_rate).to eq(50.0)
    end

    it "returns nil when there are no attendances" do
      expect(create(:enrollment).attendance_rate).to be_nil
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe EnrollmentPolicy, type: :policy do
  subject(:policy) { described_class.new(user, record) }

  let(:student) { create(:user) }
  let(:instructor) { create(:user, :instructor) }
  let(:admin) { create(:user, :admin) }
  let(:course) { create(:course, user: instructor) }
  let(:record) { create(:enrollment, user: student, course: course) }

  context "for anonymous users" do
    let(:user) { nil }

    it { is_expected.to forbid_action(:create) }
    it { is_expected.to forbid_action(:show) }
    it { is_expected.to forbid_action(:destroy) }
    it { is_expected.to forbid_action(:renew) }
    it { is_expected.to forbid_action(:attendance) }
  end

  context "for the enrollment owner" do
    let(:user) { student }

    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:destroy) }
    it { is_expected.to permit_action(:renew) }
    it { is_expected.to forbid_action(:attendance) }
  end

  context "for another student" do
    let(:user) { create(:user) }

    it { is_expected.to permit_action(:create) }
    it { is_expected.to forbid_action(:show) }
    it { is_expected.to forbid_action(:destroy) }
    it { is_expected.to forbid_action(:renew) }
    it { is_expected.to forbid_action(:attendance) }
  end

  context "for the course instructor" do
    let(:user) { instructor }

    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to permit_action(:destroy) }
    it { is_expected.to forbid_action(:renew) }
    it { is_expected.to permit_action(:attendance) }
  end

  context "for an unrelated instructor" do
    let(:user) { create(:user, :instructor) }

    it { is_expected.to forbid_action(:show) }
    it { is_expected.to forbid_action(:attendance) }
  end

  context "for admins" do
    let(:user) { admin }

    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to permit_action(:destroy) }
    it { is_expected.to permit_action(:attendance) }
  end

  describe EnrollmentPolicy::Scope do
    let!(:student_record) { create(:enrollment) }
    let!(:instructor_course) { create(:course) }
    let!(:instructor_record) { create(:enrollment, course: instructor_course) }

    it "shows own enrollments to students" do
      user = create(:user)
      own = create(:enrollment, user: user)
      expect(described_class.new(user, Enrollment).resolve).to match_array([ own ])
    end

    it "shows enrollments of the instructor's own courses" do
      user = create(:user, :instructor)
      instructor_course.update!(user: user)
      expect(described_class.new(user, Enrollment).resolve).to match_array([ instructor_record ])
    end

    it "shows every enrollment to admins" do
      user = create(:user, :admin)
      expect(described_class.new(user, Enrollment).resolve).to match_array(
        [ student_record, instructor_record ]
      )
    end
  end
end

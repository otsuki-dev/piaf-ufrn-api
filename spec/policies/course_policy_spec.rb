# frozen_string_literal: true

require "rails_helper"

RSpec.describe CoursePolicy, type: :policy do
  subject(:policy) { described_class.new(user, record) }

  let(:record) { build(:course) }

  context "for anonymous users" do
    let(:user) { nil }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to forbid_action(:create) }
    it { is_expected.to forbid_action(:update) }
    it { is_expected.to forbid_action(:destroy) }
  end

  context "for students" do
    let(:user) { build(:user) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to forbid_action(:create) }
    it { is_expected.to forbid_action(:update) }
    it { is_expected.to forbid_action(:destroy) }
    it { is_expected.to forbid_action(:attendance) }
  end

  context "for instructors" do
    let(:user) { build(:user, :instructor) }

    it { is_expected.to permit_action(:create) }

    context "on their own course" do
      let(:record) { build(:course, user: user) }

      it { is_expected.to permit_action(:update) }
      it { is_expected.to permit_action(:destroy) }
      it { is_expected.to permit_action(:attendance) }
    end

    context "on an orphan course" do
      let(:record) { build(:course, user: nil) }

      it { is_expected.to permit_action(:update) }
    end

    context "on another instructor's course" do
      let(:record) { build(:course, user: create(:user, :instructor)) }

      it { is_expected.to forbid_action(:update) }
      it { is_expected.to forbid_action(:destroy) }
    end
  end

  context "for admins" do
    let(:user) { build(:user, :admin) }
    let(:record) { build(:course, user: build(:user, :instructor)) }

    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to permit_action(:destroy) }
    it { is_expected.to permit_action(:attendance) }
  end

  describe CoursePolicy::Scope do
    let!(:own) { create(:course) }
    let!(:orphan) { create(:course, :without_instructor) }
    let!(:foreign) { create(:course, user: create(:user, :instructor)) }

    it "shows everything to admins" do
      user = create(:user, :admin)
      expect(described_class.new(user, Course).resolve).to match_array([ own, orphan, foreign ])
    end

    it "shows own and orphan courses to instructors" do
      user = create(:user, :instructor)
      own.update!(user: user)
      expect(described_class.new(user, Course).resolve).to match_array([ own, orphan ])
    end

    it "shows everything to students" do
      user = create(:user)
      expect(described_class.new(user, Course).resolve).to match_array([ own, orphan, foreign ])
    end
  end

  describe "#permitted_attributes" do
    it "returns the course manageable fields" do
      expect(described_class.new(build(:user, :instructor), record).permitted_attributes)
        .to include(:start_date, :end_date, :class_time, :slots, :modality, :custom_modality, :user_id)
    end
  end
end

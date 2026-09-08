# frozen_string_literal: true

require "rails_helper"

RSpec.describe Course, type: :model do
  subject(:course) { build(:course) }

  describe "validations" do
    it { is_expected.to be_valid }

    %i[start_date end_date slots modality].each do |field|
      it { is_expected.to validate_presence_of(field) }
    end

    it { is_expected.to validate_numericality_of(:slots).is_greater_than(0).only_integer }

    it "rejects an unknown modality" do
      course.modality = "esgrima"
      expect(course).not_to be_valid
      expect(course.errors[:modality]).to be_present
    end

    it "requires custom_modality when modality is outro" do
      course.modality = "outro"
      course.custom_modality = nil
      expect(course).not_to be_valid
      expect(course.errors[:custom_modality]).to be_present
    end

    it "accepts outro modality with a custom label" do
      course.modality = "outro"
      course.custom_modality = "Ginástica laboral"
      expect(course).to be_valid
    end

    it "rejects end_date before start_date" do
      course.start_date = 2.days.from_now.to_date
      course.end_date = 1.day.from_now.to_date
      expect(course).not_to be_valid
      expect(course.errors[:end_date]).to be_present
    end

    it "rejects end_date equal to start_date" do
      course.end_date = course.start_date
      expect(course).not_to be_valid
    end

    it "rejects a regular student as instructor" do
      course.user = create(:user)
      expect(course).not_to be_valid
      expect(course.errors[:user_id]).to be_present
    end

    it "accepts an admin as instructor" do
      course.user = create(:user, :admin)
      expect(course).to be_valid
    end

    it "accepts a course without an instructor" do
      expect(build(:course, :without_instructor)).to be_valid
    end
  end

  describe "#available_slots" do
    it "counts only confirmed enrollments" do
      course = create(:course, slots: 2)
      create(:enrollment, course: course)
      create(:enrollment, :waitlisted, course: course)

      expect(course.available_slots).to eq(1)
    end
  end

  describe "#full? / #open?" do
    it "considers a full course when no slots remain" do
      course = create(:course, slots: 1)
      expect(course).to be_open

      create(:enrollment, course: course)
      expect(course.reload).to be_full
      expect(course).not_to be_open
    end
  end

  describe "#status" do
    it "returns :closed for finished courses" do
      course = create(:course, start_date: 30.days.ago.to_date, end_date: 1.day.ago.to_date)
      expect(course.status).to eq(:closed)
    end

    it "returns :full when there are no slots left" do
      course = create(:course, slots: 1)
      create(:enrollment, course: course)
      expect(course.status).to eq(:full)
    end

    it "returns :open otherwise" do
      expect(course.status).to eq(:open)
    end
  end

  describe "#modality_label" do
    it "returns the custom label for outro" do
      course.modality = "outro"
      course.custom_modality = "Bicicleta"
      expect(course.modality_label).to eq("Bicicleta")
    end

    it "returns the modality identifier otherwise" do
      expect(build(:course, modality: "natacao").modality_label).to eq("natacao")
    end
  end

  describe "scopes" do
    let!(:finished) { create(:course, start_date: 60.days.ago.to_date, end_date: 2.days.ago.to_date) }
    let!(:current) { create(:course, :nursing, start_date: 1.day.from_now.to_date, end_date: 90.days.from_now.to_date) }

    it "includes only active courses" do
      expect(Course.active).to contain_exactly(current)
      expect(Course.active).not_to include(finished)
    end

    it "orders upcoming courses by start date" do
      expect(Course.upcoming).to eq([ current ])
    end

    it "filters by modality" do
      expect(Course.by_modality("natacao")).to eq([ current ])
      expect(Course.by_modality(nil)).to include(current, finished)
    end
  end

  describe "paper trail" do
    it "records versions" do
      persisted = create(:course)
      expect { persisted.update!(slots: 15) }
        .to change { persisted.versions.reload.count }.by(1)
    end
  end
end

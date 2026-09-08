# frozen_string_literal: true

class Attendance < ApplicationRecord
  belongs_to :enrollment

  validates :date, presence: true
  validates :date, uniqueness: { scope: :enrollment_id }
  validate :date_within_course_period

  scope :present, -> { where(present: true) }
  scope :absent, -> { where(present: false) }
  scope :ordered, -> { order(date: :asc) }

  def self.record_for(enrollment:, date:, present: true)
    attendance = enrollment.attendances.find_or_initialize_by(date: date.to_date)
    attendance.present = present
    attendance.save!
    attendance
  end

  private

  def date_within_course_period
    return if enrollment.blank? || date.blank?
    return if enrollment.course.blank?

    start_date = enrollment.course.start_date&.to_date
    end_date = enrollment.course.end_date&.to_date

    errors.add(:date, :after_course_start) if start_date.present? && date < start_date
    errors.add(:date, :before_course_end) if end_date.present? && date > end_date
  end
end

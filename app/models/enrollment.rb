# frozen_string_literal: true

class Enrollment < ApplicationRecord
  has_paper_trail

  STATUSES = %w[pending confirmed waitlisted cancelled inactive].freeze

  enum :status, {
    pending: "pending",
    confirmed: "confirmed",
    waitlisted: "waitlisted",
    cancelled: "cancelled",
    inactive: "inactive"
  }, validate: true

  ANAMNESIS_ATTRIBUTES = %i[
    heart_problem chest_pain recent_chest_pain dizziness bone_problem
    blood_pressure_meds other_reasons physical_activity_responsibility
    terms_accepted
  ].freeze

  belongs_to :user, inverse_of: :enrollments
  belongs_to :course, inverse_of: :enrollments
  belongs_to :renewed_from_enrollment, class_name: "Enrollment", optional: true
  has_one :renewal, class_name: "Enrollment", foreign_key: :renewed_from_enrollment_id,
                    dependent: :nullify, inverse_of: :renewed_from_enrollment
  has_many :attendances, dependent: :destroy

  before_validation :downcase_status
  before_destroy :remember_confirmed_status

  # A user can only be enrolled (pending/confirmed/waitlisted/inactive) once
  # per course. A cancelled enrollment frees the spot for re-enrollment.
  validates :user_id, uniqueness: { scope: :course_id, conditions: -> { where.not(status: :cancelled) } }
  validates :terms_accepted, acceptance: { accept: [ true, "1", 1 ], allow_nil: false }

  after_commit :notify_creation, on: :create
  after_commit :notify_status_change, on: :update, if: -> { saved_change_to_status? }
  after_commit :promote_waitlist_when_slot_freed, on: :update, if: -> { slot_was_freed? }
  after_commit :promote_waitlist_when_confirmed_destroyed, on: :destroy, if: -> { confirmed_before_destroy? }

  scope :active, -> { where.not(status: %w[cancelled inactive]) }
  scope :active_in_course, lambda { |course|
    where(course: course).where.not(status: %w[cancelled inactive])
  }
  scope :waiting, -> { where(status: :waitlisted).order(:created_at) }
  scope :for_course, ->(course) { where(course: course) }
  scope :recently_created, -> { order(created_at: :desc) }
  scope :without_recent_attendance, lambda { |since: 2.weeks.ago|
    where.not(id: Attendance.present.where(date: since..).select(:enrollment_id))
  }
  # Confirmed enrollments on still-running courses with zero present
  # attendances inside the window: candidates for automatic deactivation.
  scope :inactive_candidates, lambda { |since: 2.weeks.ago|
    confirmed.where.not(id: Attendance.where(present: true, date: since..).select(:enrollment_id))
             .joins(:course).merge(Course.active)
  }

  def self.enroll!(user:, course:, attributes: {})
    transaction do
      course.lock!
      status = course.full? ? :waitlisted : :confirmed
      create!(attributes.merge(user: user, course: course, status: status))
    end
  end

  def renew!(course:, attributes: {})
    base = attributes_for_renewal.merge(attributes).merge(renewed_from_enrollment_id: id)
    self.class.transaction do
      update!(status: :cancelled) if course.id == course_id
      self.class.enroll!(user: user, course: course, attributes: base)
    end
  end

  def cancel!
    update!(status: :cancelled)
  end

  def deactivate!
    update!(status: :inactive)
  end

  def reinsert!
    self.class.transaction do
      course.lock!
      update!(status: course.full? ? :waitlisted : :confirmed)
    end
  end

  def mark_attendance!(date:, present: true)
    Attendance.record_for(enrollment: self, date: date, present: present)
  end

  def attendance_rate
    total = attendances.count
    return nil if total.zero?

    (100.0 * attendances.present.count / total).round(1)
  end

  # Expires pending (unconfirmed) enrollments older than the window.
  def self.expire_pending!(expired_before: 7.days.ago)
    active.where(status: :pending).where(created_at: ...expired_before).find_each do |enrollment|
      enrollment.update!(status: :cancelled)
    end
  end

  # Deactivates students who never showed up and promotes any freed waitlist.
  def self.deactivate_inactive_students!(since: 2.weeks.ago)
    transaction do
      inactive_candidates(since: since).find_each(&:deactivate!)
    end
  end

  # Promotes as many waitlisted enrollment as there are open slots, in
  # chronological order.
  def self.promote_waitlist!(course)
    transaction do
      course.lock!
      while course.available_slots.positive?
        next_up = waiting.for_course(course).first
        break unless next_up

        next_up.update!(status: :confirmed)
      end
    end
  end

  private

  def attributes_for_renewal
    attributes.symbolize_keys.slice(*ANAMNESIS_ATTRIBUTES).merge(terms_accepted: true)
  end

  def downcase_status
    self.status = status.to_s.downcase if attribute_present?(:status)
  end

  def remember_confirmed_status
    @confirmed_before_destroy = confirmed?
  end

  def notify_creation
    EnrollmentMailer.with(enrollment: self).send(status == "waitlisted" ? :waitlisted : :confirmed).deliver_later
  end

  def notify_status_change
    return unless saved_change_to_status?

    case status
    when "confirmed"
      EnrollmentMailer.with(enrollment: self).waitlist_promoted.deliver_later
    when "cancelled"
      EnrollmentMailer.with(enrollment: self).cancelled.deliver_later
    when "inactive"
      EnrollmentMailer.with(enrollment: self).inactive.deliver_later
    end
  end

  def slot_was_freed?
    saved_change_to_status? &&
      status.in?(%w[cancelled inactive]) &&
      status_before_last_save.in?(%w[confirmed waitlisted])
  end

  def promote_waitlist_when_slot_freed
    self.class.promote_waitlist!(course)
  end

  def promote_waitlist_when_confirmed_destroyed
    self.class.promote_waitlist!(course)
  end

  def confirmed_before_destroy?
    @confirmed_before_destroy
  end
end

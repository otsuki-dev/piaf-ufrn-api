# frozen_string_literal: true

class Course < ApplicationRecord
  has_paper_trail

  MODALITIES = %w[
    musculacao natacao hidroginastica corrida treinamento_funcional
    futebol futsal volei basketball handebol judo jiu_jitsu kung_fu
    yoga pilates ritmos danca outro
  ].freeze

  belongs_to :user, optional: true, inverse_of: :courses
  has_many :enrollments, dependent: :destroy, inverse_of: :course
  has_many :attendances, through: :enrollments
  has_many :students, through: :enrollments, source: :user

  before_validation :normalize_modality

  validates :start_date, :end_date, :slots, :modality, presence: true
  validates :slots, numericality: { only_integer: true, greater_than: 0 }
  validates :modality, inclusion: { in: MODALITIES }
  validates :custom_modality, presence: true, if: -> { modality == "outro" }
  validate :end_date_after_start_date
  validate :instructor_is_valid

  scope :ordered_by_recent, -> { order(start_date: :desc) }
  scope :for_today, -> { ordered_by_recent }
  scope :active, -> { where(end_date: Time.current..) }
  scope :upcoming, -> { active.order(:start_date) }
  scope :by_modality, ->(modality) { modality.present? ? where(modality: modality) : all }

  def available_slots
    slots - enrollments.confirmed.count
  end

  def full?
    available_slots <= 0
  end

  def open?
    !full?
  end

  def status
    return :closed if end_date.present? && end_date < Time.current
    return :full if full?

    :open
  end

  def modality_label
    modality == "outro" ? custom_modality : modality
  end

  private

  def normalize_modality
    self.modality = modality.to_s.strip.downcase if attribute_present?(:modality)
  end

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?
    return if end_date > start_date

    errors.add(:end_date, :greater_than, count: start_date)
  end

  def instructor_is_valid
    return if user_id.blank?
    return if user.instructor? || user.admin?

    errors.add(:user_id, :must_be_instructor)
  end
end

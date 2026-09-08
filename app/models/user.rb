# frozen_string_literal: true

class User < ApplicationRecord
  include CpfValidatable

  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :confirmable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  # Sensitive personal data is encrypted at the application layer (LGPD).
  # `cpf` is deterministic so lookups and the unique index keep working.
  encrypts :cpf, deterministic: true
  encrypts :rg_user, :address, :cep, :district, :phone_number, :ufrn_registration_number

  has_many :enrollments, dependent: :destroy
  has_many :courses, dependent: :nullify
  has_many :attendances, through: :enrollments

  before_validation :normalize_fields

  validates :username, presence: true,
                       uniqueness: { case_sensitive: false },
                       format: { with: /\A[a-zA-Z0-9._]+\z/ },
                       length: { minimum: 3, maximum: 30 }
  validates :cpf, presence: true, uniqueness: true
  validates :birthdate, presence: true

  scope :admins, -> { where(admin: true) }
  scope :instructors, -> { where(instructor: true) }
  scope :students, -> { where(admin: false, instructor: false) }
  scope :confirmed_accounts, -> { where.not(confirmed_at: nil) }

  def role
    return :admin if admin?
    return :instructor if instructor?

    :student
  end

  def admin?
    admin == true
  end

  def instructor?
    instructor == true
  end

  def student?
    !admin? && !instructor?
  end

  def name
    username.presence || email
  end

  def masked_cpf
    return nil if cpf.blank?

    format_cpf = cpf.gsub(/\D/, "")
    "***.***.***-#{format_cpf.last(2)}"
  end

  private

  def normalize_fields
    self.email = email.to_s.strip.downcase if attribute_present?(:email)
    self.username = username.to_s.strip if attribute_present?(:username)
    self.cpf = cpf.to_s.gsub(/\D/, "") if attribute_present?(:cpf)
    self.phone_number = phone_number.to_s.gsub(/\D/, "") if attribute_present?(:phone_number)
    self.cep = cep.to_s.gsub(/\D/, "") if attribute_present?(:cep)
  end
end

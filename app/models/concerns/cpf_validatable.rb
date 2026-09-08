# frozen_string_literal: true

module CpfValidatable
  extend ActiveSupport::Concern

  include ActiveModel::Validations

  CPF_REGEX = /\A\d{11}\z/i

  included do
    validate :cpf_is_valid, if: -> { attribute_present?(:cpf) && cpf.present? }
  end

  def cpf_is_valid
    unless self.class.cpf_valid?(cpf)
      errors.add(:cpf, :invalid)
    end
  end

  class_methods do
    def cpf_valid?(value)
      digits = value.to_s.gsub(/\D/, "")
      return false unless digits.match?(CPF_REGEX)
      return false if digits.chars.uniq.size == 1

      first = check_digit(digits[0, 9], 10)
      second = check_digit(digits[0, 10], 11)

      digits[9] == first.to_s && digits[10] == second.to_s
    end

    private

    def check_digit(body, factor)
      total = body.chars.each_with_index.sum do |char, index|
        char.to_i * (factor - index)
      end
      rest = (total * 10) % 11
      rest == 10 ? 0 : rest
    end
  end
end

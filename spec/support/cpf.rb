# frozen_string_literal: true

module SpecSupport
  # Deterministic generator of structurally valid Brazilian CPFs so factories
  # do not need to hard-code a fixed document number.
  module Cpf
    module_function

    def valid(n)
      stem = format("%09d", n % 1_000_000_000).chars.map(&:to_i)
      stem = [ 9, 8, 7, 6, 5, 4, 3, 2, 1 ] if stem.uniq.size == 1

      first = check_digit(stem, 10)
      second = check_digit(stem + [ first ], 11)

      (stem + [ first, second ]).join
    end

    def check_digit(body, factor)
      total = body.each_with_index.sum { |digit, index| digit * (factor - index) }
      rest = (total * 10) % 11
      rest == 10 ? 0 : rest
    end
  end
end

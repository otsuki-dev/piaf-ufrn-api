# frozen_string_literal: true

FactoryBot.define do
  factory :attendance do
    association :enrollment
    date { enrollment.course.start_date.to_date }
    present { true }

    trait :absent do
      present { false }
    end
  end
end

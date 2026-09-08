# frozen_string_literal: true

FactoryBot.define do
  factory :course do
    association :user, factory: %i[user instructor]
    modality { "musculacao" }
    custom_modality { nil }
    class_time { "18:00" }
    start_date { 1.day.from_now.to_date }
    end_date { 90.days.from_now.to_date }
    slots { 20 }

    trait :without_instructor do
      user { nil }
    end

    trait :outro_modality do
      modality { "outro" }
      custom_modality { "Ginástica laboral" }
    end

    trait :nursing do
      modality { "natacao" }
    end
  end
end

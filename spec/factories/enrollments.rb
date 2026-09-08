# frozen_string_literal: true

FactoryBot.define do
  factory :enrollment do
    association :user
    association :course
    terms_accepted { true }
    status { "confirmed" }

    trait :pending do
      status { "pending" }
    end

    trait :waitlisted do
      status { "waitlisted" }
    end

    trait :cancelled do
      status { "cancelled" }
    end

    trait :inactive do
      status { "inactive" }
    end

    trait :with_anamnesis do
      heart_problem { false }
      chest_pain { false }
      recent_chest_pain { false }
      dizziness { false }
      bone_problem { false }
      blood_pressure_meds { false }
      other_reasons { "Nenhum" }
      physical_activity_responsibility { true }
    end
  end
end

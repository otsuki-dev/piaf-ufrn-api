# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "usuario_#{n}" }
    sequence(:email) { |n| "usuario#{n}@exemplo.com" }
    password { "senhasegura123" }
    password_confirmation { "senhasegura123" }
    sequence(:cpf) { |n| SpecSupport::Cpf.valid(n + 10_000) }
    birthdate { 30.years.ago.to_date }
    ufrn_student { true }

    confirmed_at { Time.current }

    trait :unconfirmed do
      confirmed_at { nil }
      confirmation_sent_at { Time.current }
    end

    trait :admin do
      admin { true }
      instructor { false }
    end

    trait :instructor do
      admin { false }
      instructor { true }
    end
  end
end

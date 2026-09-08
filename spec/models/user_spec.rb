# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  describe "validations" do
    it { is_expected.to be_valid }

    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_presence_of(:cpf) }
    it { is_expected.to validate_presence_of(:birthdate) }
    it do
      expect(user).to validate_uniqueness_of(:username).case_insensitive
    end

    it "validates cpf uniqueness" do
      first = create(:user)
      duplicate = build(:user, cpf: first.cpf)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:cpf]).to be_present
    end

    it "rejects an invalid cpf" do
      user.cpf = "12345678901"
      expect(user).not_to be_valid
      expect(user.errors[:cpf]).to be_present
    end

    it "rejects a cpf with fewer than 11 digits" do
      user.cpf = "5299822472"
      expect(user).not_to be_valid
    end

    it "rejects a cpf with repeated digits" do
      user.cpf = "11111111111"
      expect(user).not_to be_valid
    end

    it "accepts a valid cpf" do
      user.cpf = SpecSupport::Cpf.valid(530)
      expect(user).to be_valid
    end

    it { is_expected.to validate_length_of(:username).is_at_least(3).is_at_most(30) }

    it "rejects usernames with invalid characters" do
      user.username = "usuario com espaço!"
      expect(user).not_to be_valid
      expect(user.errors[:username]).to be_present
    end
  end

  describe "normalization" do
    it "strips and downcases the email" do
      user.email = "  Maria@Exemplo.COM "
      user.validate
      expect(user.email).to eq("maria@exemplo.com")
    end

    it "keeps only digits in cpf and phone_number" do
      user.cpf = "529.982.247-25"
      user.phone_number = "(84) 99999-9999"
      user.validate
      expect(user.cpf).to eq("52998224725")
      expect(user.phone_number).to eq("84999999999")
    end
  end

  describe "encrypted PII" do
    it "stores the cpf encrypted at rest" do
      saved = create(:user, cpf: SpecSupport::Cpf.valid(701))
      raw = User.connection.select_value("SELECT cpf FROM users WHERE id = #{saved.id}")
      expect(raw).not_to include(SpecSupport::Cpf.valid(701))
    end

    it "finds users by the deterministic cpf" do
      saved = create(:user, cpf: SpecSupport::Cpf.valid(702))
      expect(User.find_by(cpf: saved.cpf)).to eq(saved)
    end
  end

  describe "#role" do
    it "returns :admin for admins" do
      expect(build(:user, :admin).role).to eq(:admin)
    end

    it "returns :instructor for instructors" do
      expect(build(:user, :instructor).role).to eq(:instructor)
    end

    it "returns :student for regular users" do
      expect(build(:user).role).to eq(:student)
    end
  end

  describe "#role predicates" do
    it { expect(build(:user, :admin)).to be_admin }
    it { expect(build(:user, :instructor)).to be_instructor }
    it { expect(build(:user)).to be_student }
  end

  describe "#masked_cpf" do
    it "masks everything but the last two digits" do
      user.cpf = "52998224725"
      expect(user.masked_cpf).to eq("***.***.***-25")
    end
  end

  describe "#name" do
    it "prefers the username" do
      user.username = "joao"
      expect(user.name).to eq("joao")
    end
  end

  describe "scopes" do
    let!(:admin) { create(:user, :admin) }
    let!(:instructor) { create(:user, :instructor) }
    let!(:student) { create(:user) }
    let!(:unconfirmed) { create(:user, :unconfirmed) }

    it { expect(User.admins).to eq([ admin ]) }
    it { expect(User.instructors).to eq([ instructor ]) }
    it { expect(User.students).to include(student) }
    it { expect(User.students).not_to include(admin, instructor) }
    it { expect(User.confirmed_accounts).to match_array([ admin, instructor, student ]) }
  end

  describe "devise integration" do
    it "is confirmable" do
      expect(user).to respond_to(:confirmed_at, :confirmation_token)
    end

    it "is validatable" do
      user.password = "123"
      expect(user).not_to be_valid
      expect(user.errors[:password]).to be_present
    end
  end
end

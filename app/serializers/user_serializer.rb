# frozen_string_literal: true

class UserSerializer < Blueprinter::Base
  identifier :id

  fields :username, :email, :role

  field :masked_cpf

  view :default do
    fields :ufrn_student, :birthdate
  end

  view :me do
    fields :ufrn_student, :ufrn_registration_number, :phone_number,
           :district, :cep, :address, :birthdate, :created_at, :updated_at
  end

  # Only privileged contexts may see the full personal data.
  view :admin do
    fields :cpf, :rg_user, :address, :cep, :district, :phone_number,
           :ufrn_registration_number, :birthdate, :ufrn_student,
           :admin, :instructor, :created_at, :updated_at
  end
end

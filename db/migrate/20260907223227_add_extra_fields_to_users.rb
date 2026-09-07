class AddExtraFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :username, :string
    add_index :users, :username, unique: true
    add_column :users, :cpf, :string
    add_index :users, :cpf, unique: true
    add_column :users, :birthdate, :date
    add_column :users, :ufrn_student, :boolean
    add_column :users, :ufrn_registration_number, :string
    add_column :users, :admin, :boolean
    add_column :users, :phone_number, :string
    add_column :users, :rg_user, :string
    add_column :users, :address, :string
    add_column :users, :cep, :string
    add_column :users, :district, :string
    add_column :users, :instructor, :boolean
  end
end

class PrepareSensitiveUserColumnsForEncryption < ActiveRecord::Migration[8.1]
  def change
    reversible do |dir|
      dir.up do
        change_column_default :users, :admin, false
        change_column_default :users, :instructor, false
        change_column_null :users, :admin, false, false
        change_column_null :users, :instructor, false, false
      end

      dir.down do
        change_column_default :users, :admin, nil
        change_column_default :users, :instructor, nil
        change_column_null :users, :admin, true
        change_column_null :users, :instructor, true
      end
    end

    change_column :users, :cpf, :text
    change_column :users, :rg_user, :text
    change_column :users, :phone_number, :text
    change_column :users, :address, :text
    change_column :users, :cep, :text
    change_column :users, :district, :text
    change_column :users, :ufrn_registration_number, :text
  end
end

class AddStatusToEnrollments < ActiveRecord::Migration[8.1]
  def change
    add_column :enrollments, :status, :string, null: false, default: "pending"
    add_index :enrollments, [ :course_id, :status ]
  end
end

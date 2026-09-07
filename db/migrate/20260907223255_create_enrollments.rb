class CreateEnrollments < ActiveRecord::Migration[8.1]
  def change
    create_table :enrollments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.boolean :terms_accepted
      t.boolean :heart_problem
      t.boolean :chest_pain
      t.boolean :recent_chest_pain
      t.boolean :dizziness
      t.boolean :bone_problem
      t.boolean :blood_pressure_meds
      t.boolean :other_reasons
      t.boolean :physical_activity_responsibility

      t.timestamps
    end
  end
end

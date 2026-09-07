class CreateCourses < ActiveRecord::Migration[8.1]
  def change
    create_table :courses do |t|
      t.datetime :start_date
      t.datetime :end_date
      t.string :class_time
      t.integer :slots
      t.string :modality
      t.string :custom_modality
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end

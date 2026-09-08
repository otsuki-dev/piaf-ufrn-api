class MakeCourseInstructorOptionalAndTrackRenewal < ActiveRecord::Migration[8.1]
  def change
    change_column_null :courses, :user_id, true
    add_column :enrollments, :renewed_from_enrollment_id, :bigint
  end
end

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_07_230006) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "attendances", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.bigint "enrollment_id", null: false
    t.boolean "present", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["enrollment_id", "date"], name: "index_attendances_on_enrollment_id_and_date", unique: true
    t.index ["enrollment_id"], name: "index_attendances_on_enrollment_id"
  end

  create_table "courses", force: :cascade do |t|
    t.string "class_time"
    t.datetime "created_at", null: false
    t.string "custom_modality"
    t.datetime "end_date"
    t.string "modality"
    t.integer "slots"
    t.datetime "start_date"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_courses_on_user_id"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "attempts", default: 0, null: false
    t.datetime "created_at"
    t.datetime "failed_at"
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "locked_at"
    t.string "locked_by"
    t.integer "priority", default: 0, null: false
    t.string "queue"
    t.datetime "run_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "enrollments", force: :cascade do |t|
    t.boolean "blood_pressure_meds"
    t.boolean "bone_problem"
    t.boolean "chest_pain"
    t.bigint "course_id", null: false
    t.datetime "created_at", null: false
    t.boolean "dizziness"
    t.boolean "heart_problem"
    t.boolean "other_reasons"
    t.boolean "physical_activity_responsibility"
    t.boolean "recent_chest_pain"
    t.bigint "renewed_from_enrollment_id"
    t.string "status", default: "pending", null: false
    t.boolean "terms_accepted"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["course_id", "status"], name: "index_enrollments_on_course_id_and_status"
    t.index ["course_id"], name: "index_enrollments_on_course_id"
    t.index ["user_id"], name: "index_enrollments_on_user_id"
  end

  create_table "jwt_denylist", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "exp", null: false
    t.string "jti", null: false
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_jwt_denylist_on_jti"
  end

  create_table "users", force: :cascade do |t|
    t.text "address"
    t.boolean "admin", default: false, null: false
    t.date "birthdate"
    t.text "cep"
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.text "cpf"
    t.datetime "created_at", null: false
    t.text "district"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.boolean "instructor", default: false, null: false
    t.text "phone_number"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.text "rg_user"
    t.text "ufrn_registration_number"
    t.boolean "ufrn_student"
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["cpf"], name: "index_users_on_cpf", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.datetime "created_at"
    t.string "event", null: false
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.text "object"
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "attendances", "enrollments"
  add_foreign_key "courses", "users"
  add_foreign_key "enrollments", "courses"
  add_foreign_key "enrollments", "users"
end

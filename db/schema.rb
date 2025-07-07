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

ActiveRecord::Schema[8.0].define(version: 2025_07_04_135536) do
  create_table "exams", force: :cascade do |t|
    t.string "title", null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.integer "manager_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["manager_id"], name: "index_exams_on_manager_id"
  end

  create_table "question_options", force: :cascade do |t|
    t.string "content", null: false
    t.boolean "correct", default: false, null: false
    t.integer "question_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_question_options_on_question_id"
  end

  create_table "question_options_user_answers", id: false, force: :cascade do |t|
    t.integer "question_option_id", null: false
    t.integer "user_answer_id", null: false
  end

  create_table "questions", force: :cascade do |t|
    t.text "content", null: false
    t.string "question_type", null: false
    t.boolean "scorable", default: true, null: false
    t.integer "score"
    t.integer "exam_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exam_id"], name: "index_questions_on_exam_id"
  end

  create_table "user_answers", force: :cascade do |t|
    t.integer "user_exam_id", null: false
    t.integer "question_id", null: false
    t.text "text_answer"
    t.boolean "text_answer_correct", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_user_answers_on_question_id"
    t.index ["user_exam_id"], name: "index_user_answers_on_user_exam_id"
  end

  create_table "user_exams", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "exam_id", null: false
    t.integer "score"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exam_id"], name: "index_user_exams_on_exam_id"
    t.index ["user_id"], name: "index_user_exams_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role", default: "student"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "exams", "users", column: "manager_id"
  add_foreign_key "question_options", "questions"
  add_foreign_key "questions", "exams"
  add_foreign_key "user_answers", "questions"
  add_foreign_key "user_answers", "user_exams"
  add_foreign_key "user_exams", "exams"
  add_foreign_key "user_exams", "users"
end

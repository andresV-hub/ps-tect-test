class CreateUserExams < ActiveRecord::Migration[8.0]
  def change
    create_table :user_exams do |t|
      t.references :user, null: false, foreign_key: true
      t.references :exam, null: false, foreign_key: true
      t.integer :score
      t.datetime :completed_at

      t.timestamps
    end
  end
end

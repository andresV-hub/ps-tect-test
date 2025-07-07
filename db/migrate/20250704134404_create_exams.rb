class CreateExams < ActiveRecord::Migration[8.0]
  def change
    create_table :exams do |t|
      t.string :title, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.references :manager, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end

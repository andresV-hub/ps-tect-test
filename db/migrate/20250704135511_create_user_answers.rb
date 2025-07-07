class CreateUserAnswers < ActiveRecord::Migration[8.0]
  def change
    create_table :user_answers do |t|
      t.references :user_exam, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.text :text_answer
      t.boolean :text_answer_correct, default: false
      t.timestamps
    end
  end
end

class CreateQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :questions do |t|
      t.text :content, null: false
      t.string :question_type, null: false
      t.boolean :scorable, null: false, default: true
      t.integer :score
      t.references :exam, null: false, foreign_key: true

      t.timestamps
    end
  end
end

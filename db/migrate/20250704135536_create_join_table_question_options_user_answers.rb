class CreateJoinTableQuestionOptionsUserAnswers < ActiveRecord::Migration[8.0]
  def change
    create_join_table :question_options, :user_answers do |t|
      # t.index [:question_option_id, :user_answer_id]
      # t.index [:user_answer_id, :question_option_id]
    end
  end
end

class UserExam < ApplicationRecord
  belongs_to :user
  belongs_to :exam
  has_many :user_answers, dependent: :destroy
  accepts_nested_attributes_for :user_answers, allow_destroy: true

  validates :user_id, uniqueness: { scope: :exam_id }

  def calculate_score!
    total = 0.0
    user_answers.includes(:question, :question_options).find_each do |answer|
      question = answer.question
      next unless question.scorable?
      if question.text?
        total += question.score if answer&.text_answer_correct
      elsif question.single_choice?
        selected_option = answer.question_options.first
        total += question.score if selected_option&.correct?
      elsif question.multiple_choice?
        correct_ids = question.question_options.where(correct: true).pluck(:id).sort
        selected_ids = answer.question_options.pluck(:id).sort
        total += question.score if correct_ids == selected_ids
      end
    end
    update!(score: total, completed_at: Time.current)
  end

  scope :completed, -> { where.not(completed_at: nil) }

end

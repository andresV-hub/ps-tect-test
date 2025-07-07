class UserAnswer < ApplicationRecord
  belongs_to :user_exam
  belongs_to :question

  has_and_belongs_to_many :question_options

  validates :text_answer, presence: true, if: -> { question.text? }
  validate :selection_made_for_choice_question, if: -> { question.single_choice? || question.multiple_choice? }

  private
  def selection_made_for_choice_question
    if question.single_choice?
      if question_options.size != 1
        errors.add(:question_options, "must select exactly one option for single choice question")
      end
    elsif question.multiple_choice?
      if question_options.size < 1
        errors.add(:question_options, "must select at least one option for multiple choice question")
      end
    end
  end
end
class Question < ApplicationRecord
  belongs_to :exam
  has_many :question_options, dependent: :destroy
  has_many :user_answers, dependent: :destroy
  accepts_nested_attributes_for :question_options, allow_destroy: true

  VALID_QUESTION_TYPES = %w[text multiple_choice single_choice]

  validates :question_type, inclusion: { in: VALID_QUESTION_TYPES }
  validates :content, presence: true
  validates :score, numericality: { greater_than_or_equal_to: 0 }, if: :scorable?
  validates :score, presence: true, if: :scorable?
  validate :valid_options_for_choice_types, if: -> { multiple_choice? || single_choice? }
  validate :no_options_for_text_type, if: :text?

  def text?
    question_type == 'text'
  end

  def multiple_choice?
    question_type == 'multiple_choice'
  end

  def single_choice?
    question_type == 'single_choice'
  end

  def scorable?
    scorable
  end


  private

  def valid_options_for_choice_types
    if question_options.empty?
      errors.add(:question_options, :must_have_at_least_one_option)
    end

    if question_options.reject(&:marked_for_destruction?).select(&:correct?).count == question_options.reject(&:marked_for_destruction?).count
      errors.add(:question_options, :must_have_at_least_one_incorrect_option)
    end

    if single_choice?
      if question_options.reject(&:marked_for_destruction?).select(&:correct?).count != 1
        errors.add(:question_options, :must_have_exactly_one_correct_option_for_single_choice)
      end
    elsif multiple_choice?
      if question_options.reject(&:marked_for_destruction?).select(&:correct?).count <= 1
        errors.add(:question_options, :must_have_at_least_two_correct_option_for_multiple_choice)
      end
    end
  end

  def no_options_for_text_type
    if question_options.reject(&:marked_for_destruction?).any?
      errors.add(:question_options, :cannot_have_options_for_text_type)
    end
  end

end

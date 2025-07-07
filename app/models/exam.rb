class Exam < ApplicationRecord

  belongs_to :manager, class_name: 'User'
  has_many :questions, inverse_of: :exam, dependent: :destroy
  has_many :user_exams, dependent: :destroy
  has_many :users, through: :user_exams
  accepts_nested_attributes_for :questions, allow_destroy: true

  validates :title, :start_date, :end_date, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :valid_date_range

  scope :available_for_user, ->(user) {
    where('start_date <= ? AND end_date >= ?', Time.current, Time.current)
      .where.not(id: user.user_exams.pluck(:exam_id))
  }

  scope :completed_by_user, ->(user) {
    joins(:user_exams).where(user_exams: { user_id: user.id, completed_at: !nil })
  }

  def valid_date_range
    if start_date.present? && end_date.present?
      if end_date <= start_date
        errors.add(:end_date, :must_be_after_start_date)
      end
    end
  end

  def available_now?
    start_date <= Time.current && end_date >= Time.current
  end

  def total_score
    questions.where(scorable: true).sum(:score)
  end

  filterrific(
    default_filter_params: { sorted_by: 'start_date_desc' },
    available_filters: [
      :sorted_by,
      :with_start_date_gte,
      :with_start_date_lte,
      :with_end_date_gte,
      :with_end_date_lte
    ]
  )

  scope :sorted_by, ->(sort_option) {
    direction = (sort_option =~ /desc$/) ? 'desc' : 'asc'
    case sort_option.to_s
    when /^title_/
      order("LOWER(exams.title) #{direction}")
    when /^start_date_/
      order("exams.start_date #{direction}")
    when /^end_date_/
      order("exams.end_date #{direction}")
    else
      raise(ArgumentError, "Invalid sort option: #{sort_option.inspect}")
    end
  }

  scope :with_start_date_gte, ->(start_date) {
    where('exams.start_date >= ?', start_date) if start_date.present?
  }

  scope :with_end_date_gte, ->(end_date) {
    where('exams.end_date >= ?', end_date) if end_date.present?
  }

  scope :with_start_date_lte, ->(start_date) {
    where('exams.start_date <= ?', start_date) if start_date.present?
  }

  scope :with_end_date_lte, ->(end_date) {
    where('exams.end_date <= ?', end_date) if end_date.present?
  }

  def self.options_for_sorted_by
    [
      [I18n.t('activerecord.filterrific.exam.options_for_sorted_by.title_asc'), 'title_asc'],
      [I18n.t('activerecord.filterrific.exam.options_for_sorted_by.title_desc'), 'title_desc'],
      [I18n.t('activerecord.filterrific.exam.options_for_sorted_by.start_date_asc'), 'start_date_asc'],
      [I18n.t('activerecord.filterrific.exam.options_for_sorted_by.start_date_desc'), 'start_date_desc'],
      [I18n.t('activerecord.filterrific.exam.options_for_sorted_by.end_date_asc'), 'end_date_asc'],
      [I18n.t('activerecord.filterrific.exam.options_for_sorted_by.end_date_desc'), 'end_date_desc'],
    ]
  end

end

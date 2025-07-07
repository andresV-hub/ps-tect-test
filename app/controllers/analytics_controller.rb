class AnalyticsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin!

  def index
    @exams_created_by_month = Exam.group_by_month(:created_at).count
    @user_exams_completed_by_month = UserExam.completed.group_by_month(:completed_at).count

    @average_score_per_exam = Exam.joins(:user_exams)
                                  .select('exams.title, AVG(user_exams.score) as average_score')
                                  .group('exams.title')
                                  .order('average_score DESC')
                                  .limit(5)
                                  .map { |exam| [exam.title, exam.average_score.to_f.round(2)] }
                                  .to_h

    @students_per_exam = Exam.joins(:user_exams)
                             .group('exams.title')
                             .count('DISTINCT user_exams.user_id')
    @question_type_distribution = Question.group(:question_type).count
  end

  private

  def authorize_admin!
    unless current_user.admin?
      redirect_to root_path, alert: "You are not authorized to access this page."
    end
  end
end
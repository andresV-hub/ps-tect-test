class UserExamsController < ApplicationController
  before_action :set_exam, only: %i[new create]
  before_action :check_exam_availability, only: %i[new create]
  before_action :set_user_exam, only: %i[show]

  def index
    @user_exams = current_user.user_exams.includes(:exam).order(created_at: :desc).paginate(page: params[:page])
  end

  def show
  end

  def new
    @user_exam = current_user.user_exams.find_or_initialize_by(exam: @exam)

    if @user_exam.completed_at.present?
      redirect_to user_exam_path(@user_exam), alert: t('user_exams.already_completed_alert')
      return
    end

    @exam.questions.each do |question|
      @user_exam.user_answers.find_or_initialize_by(question: question) unless @user_exam.user_answers.any? { |ua| ua.question == question }
    end

    @user_exam.user_answers = @user_exam.user_answers.to_a
  end


  def create
    @user_exam = current_user.user_exams.find_or_initialize_by(exam: @exam)

    if @user_exam.completed_at.present?
      redirect_to user_exam_path(@user_exam), alert: t('user_exams.already_completed_alert')
      return
    end

    @user_exam.assign_attributes(user_exam_params)

    if @user_exam.save!
      @user_exam.calculate_score!
      redirect_to user_exam_path(@user_exam), notice: t('user_exams.exam_completed_notice')
    else
      @exam.questions.each do |question|
        @user_exam.user_answers.find_or_initialize_by(question: question) unless @user_exam.user_answers.any? { |ua| ua.question == question }
      end
      @user_exam.user_answers = @user_exam.user_answers.to_a
      flash.now[:alert] = t('user_exams.submission_failed_alert')
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @user_exam = UserExam.find(params[:id])
    @exam = @user_exam.exam
    @exam.questions.includes(:question_options)
    @exam.questions.each do |question|
      @user_exam.user_answers.find_or_initialize_by(question: question) unless @user_exam.user_answers.any? { |ua| ua.question == question }
    end
    @user_exam.user_answers = @user_exam.user_answers.to_a
  end

  def update
    @user_exam = UserExam.find(params[:id])
    @exam = @user_exam.exam
    @exam.questions.includes(:question_options)
    if @user_exam.update(user_exam_params)
      @user_exam.calculate_score!
      redirect_to exam_path(@exam), notice: "Examen actualizado correctamente"
    else
      @exam.questions.each do |question|
        @user_exam.user_answers.find_or_initialize_by(question: question) unless @user_exam.user_answers.any? { |ua| ua.question == question }
      end
      @user_exam.user_answers = @user_exam.user_answers.to_a
      flash.now[:alert] = t('user_exams.update_failed_alert')
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_exam
    @exam = Exam.find(params[:exam_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to exams_path, alert: t('exams.not_found_alert')
  end

  def set_user_exam
    @user_exam = current_user.user_exams.find(params[:id])
    @exam = @user_exam.exam
    @exam.questions.includes(:question_options)
  rescue ActiveRecord::RecordNotFound
    redirect_to user_exams_path, alert: t('user_exams.not_found_alert')
  end

  def user_exam_params
    params.require(:user_exam).permit(
      user_answers_attributes: [
        :id,
        :question_id,
        :text_answer,
        :text_answer_correct,
        question_option_ids: []
      ]
    )
  end

  def check_exam_availability
    unless @exam.available_now?
      redirect_to exams_path, alert: t('exams.not_available_alert')
    end
  end
end
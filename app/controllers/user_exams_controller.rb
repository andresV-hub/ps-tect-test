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
      redirect_to user_exam_path(@user_exam), alert: t("user_exams.already_completed_alert")
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
      redirect_to user_exam_path(@user_exam), alert: t("user_exams.already_completed_alert")
      return
    end

    @user_exam.assign_attributes(user_exam_params)

    if @user_exam.save!
      @user_exam.calculate_score!
      redirect_to user_exam_path(@user_exam), notice: t("user_exams.exam_completed_notice")
    else
      @exam.questions.each do |question|
        @user_exam.user_answers.find_or_initialize_by(question: question) unless @user_exam.user_answers.any? { |ua| ua.question == question }
      end
      @user_exam.user_answers = @user_exam.user_answers.to_a
      flash.now[:alert] = t("user_exams.submission_failed_alert")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    return unless set_editable_user_exam

    @exam.questions.each do |question|
      @user_exam.user_answers.find_or_initialize_by(question: question) unless @user_exam.user_answers.any? { |ua| ua.question == question }
    end
    @user_exam.user_answers = @user_exam.user_answers.to_a
  end

  def update
    return unless set_editable_user_exam

    if @user_exam.update(user_exam_params)
      @user_exam.calculate_score!
      redirect_to exam_path(@exam), notice: t("user_exams.updated_notice")
    else
      @exam.questions.each do |question|
        @user_exam.user_answers.find_or_initialize_by(question: question) unless @user_exam.user_answers.any? { |ua| ua.question == question }
      end
      @user_exam.user_answers = @user_exam.user_answers.to_a
      flash.now[:alert] = t("user_exams.update_failed_alert")
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_exam
    @exam = Exam.find(params[:exam_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to exams_path, alert: t("exams.not_found_alert")
  end

  def set_user_exam
    @user_exam = current_user.user_exams.find(params[:id])
    @exam = @user_exam.exam
    @exam.questions.includes(:question_options)
  rescue ActiveRecord::RecordNotFound
    redirect_to user_exams_path, alert: t("user_exams.not_found_alert")
  end

  # `edit` y `update` cargaban la entrega con `UserExam.find(params[:id])`, sin
  # ningún filtro: cualquier usuario autenticado podía abrir y modificar las
  # respuestas de otro. El admin corrige entregas ajenas (llega aquí desde la
  # ficha del examen), pero el alumno sólo puede tocar las suyas.
  def set_editable_user_exam
    scope = current_user.admin? ? UserExam.all : current_user.user_exams
    @user_exam = scope.find(params[:id])
    @exam = @user_exam.exam
    true
  rescue ActiveRecord::RecordNotFound
    redirect_to user_exams_path, alert: t("user_exams.not_found_alert")
    false
  end

  # `text_answer_correct` es la marca de corrección de las respuestas libres:
  # `UserExam#calculate_score!` suma la puntuación de la pregunta cuando está a
  # true. Sólo el admin puede fijarla. Antes se permitía a cualquiera, así que
  # un alumno podía aprobarse sus propias respuestas de texto.
  def user_exam_params
    permitted = [ :id, :question_id, :text_answer, { question_option_ids: [] } ]
    permitted.unshift(:text_answer_correct) if current_user.admin?

    params.require(:user_exam).permit(user_answers_attributes: permitted)
  end

  def check_exam_availability
    unless @exam.available_now?
      redirect_to exams_path, alert: t("exams.not_available_alert")
    end
  end
end

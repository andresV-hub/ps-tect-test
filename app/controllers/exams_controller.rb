class ExamsController < ApplicationController

  before_action :set_exam, only: %i[show edit update destroy]
  before_action :authorize_admin!, except: %i[index show]


  def index
    exams = current_user.admin? ? Exam.all : Exam.where("start_date <= ? AND end_date >= ?", Time.current, Time.current)
    @filterrific = initialize_filterrific(
      exams,
      params[:filterrific],
      select_options: {
        sorted_by: Exam.options_for_sorted_by,
      }
    ) or return
    @exams = @filterrific.find.page(params[:page])
    respond_to do |format|
      format.html
      format.js
    end
  end

  def show
  end

  def new
    @exam = Exam.new
    @exam.questions.build.tap do |question|
      question.question_options.build
    end
  end

  def create
    @exam = Exam.new(exam_params.merge(manager: current_user))
    @exam.questions.each_with_index do |q, i|
      Rails.logger.debug "Pregunta ##{i + 1} — question_type: #{q.question_type.inspect} (class: #{q.question_type.class.name})"
    end
    if @exam.save
      redirect_to @exam, notice: "Examen creado correctamente."
    else
      puts "aqui"
      Rails.logger.error @exam.errors.full_messages.to_sentence
      @exam.questions.each do |q|
        Rails.logger.error "Pregunta: #{q.content}, errores: #{q.errors.full_messages.join(', ')}"
      end
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @exam.update(exam_params)
      redirect_to @exam, notice: "Examen actualizado correctamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @exam.destroy
    redirect_to exams_path, notice: "Examen eliminado correctamente."
  end

  private


  def set_exam
    @exam = Exam.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to exams_path, alert: "Examen no encontrado."
  end

  def exam_params
    params.require(:exam).permit(
      :title, :start_date, :end_date,
      questions_attributes: [
        :id, :content, :question_type, :scorable, :score, :_destroy,
        question_options_attributes: [:id, :content, :correct, :_destroy]
      ]
    )
  end

  def authorize_admin!
    redirect_to root_path, alert: "Acceso denegado." unless current_user&.admin?
  end

end

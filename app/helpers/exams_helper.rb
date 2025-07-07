module ExamsHelper

  def  translated_question_type(question_type)
    I18n.t("activerecord.attributes.question.question_type.#{question_type}")
  end

end

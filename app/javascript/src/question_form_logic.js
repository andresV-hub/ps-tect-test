// Shows or hides the option and score fields of the nested question forms,
// depending on the question type and on whether the question is scorable.
//
// The delegated handlers are registered once, at module load. Registering them
// inside the turbo:load callback would add a fresh set of listeners on every
// page visit.
const $ = window.jQuery

function updateQuestionFields($container) {
  const questionType = $container.data("question-type")
  const $optionsFields = $container.find(".options-fields")

  // Antes esto también hacía `.show()` sobre `.score-fields`, un selector que
  // no existe en ninguna vista y que se mostraba en ambas ramas: no hacía
  // nada. El envoltorio real del campo de puntuación es `.score-input-group`,
  // y lo gobierna updateScorableFields(). Ver docs/styles.md §6.8.
  if (questionType === "text") {
    $optionsFields.hide()
  } else {
    $optionsFields.show()
  }
}

function updateScorableFields($container) {
  const $scorableCheckbox = $container.find(".scorable-checkbox")
  const $scoreInput = $container.find(".score-input")
  const $scoreInputGroup = $container.find(".score-input-group")
  const isScorable = $scorableCheckbox.prop("checked")

  if (isScorable) {
    $scoreInput.prop("required", true)
    $scoreInputGroup.show()
  } else {
    $scoreInput.prop("required", false).val("")
    $scoreInputGroup.hide()
  }
}

function refreshAllQuestionFields() {
  $(".nested-fields").each(function () {
    const $questionContainer = $(this)
    $questionContainer.data("question-type", $questionContainer.find(".question-type-select").val())

    updateQuestionFields($questionContainer)
    updateScorableFields($questionContainer)
  })
}

$(document).on("change", ".question-type-select", function () {
  const $questionContainer = $(this).closest(".nested-fields")
  $questionContainer.data("question-type", $(this).val())
  updateQuestionFields($questionContainer)
})

$(document).on("change", ".scorable-checkbox", function () {
  const $questionContainer = $(this).closest(".nested-fields")
  updateScorableFields($questionContainer)
})

$(document).on("turbo:load cocoon:after-insert", refreshAllQuestionFields)

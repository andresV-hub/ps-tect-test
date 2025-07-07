document.addEventListener('turbo:load', () => {
    function updateQuestionFields($container) {
        const questionType = $container.data('question-type');
        const $optionsFields = $container.find('.options-fields');
        const $scoreFields = $container.find('.score-fields');

        if (questionType === 'text') {
            $optionsFields.hide();
            $scoreFields.show();
        } else {
            $optionsFields.show();
            $scoreFields.show();
        }
    }

    function updateScorableFields($container) {
        const $scorableCheckbox = $container.find('.scorable-checkbox');
        const $scoreInput = $container.find('.score-input');
        const $scoreInputGroup = $container.find('.score-input-group');
        const isScorable = $scorableCheckbox.prop('checked');

        if (isScorable) {
            $scoreInput.prop('required', true);
            $scoreInputGroup.show();
        } else {
            $scoreInput.prop('required', false).val('');
            $scoreInputGroup.hide();
        }
    }

    $(document).on('change', '.question-type-select', function() {
        const $questionContainer = $(this).closest('.nested-fields');
        $questionContainer.data('question-type', $(this).val());
        updateQuestionFields($questionContainer);
    });

    $(document).on('change', '.scorable-checkbox', function() {
        const $questionContainer = $(this).closest('.nested-fields');
        updateScorableFields($questionContainer);
    });

    $(document).on('turbo:load cocoon:after-insert', () => {
        $('.nested-fields').each(function() {
            const $questionContainer = $(this);
            $questionContainer.data('question-type', $questionContainer.find('.question-type-select').val());

            updateQuestionFields($questionContainer);
            updateScorableFields($questionContainer);
        });
    });
});
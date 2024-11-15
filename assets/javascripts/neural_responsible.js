// assets/javascripts/neural_responsible.js
function addRuleSet() {
    var rulesets = document.querySelector('.rule-sets');
    if (!rulesets) return;

    // Получаем все существующие наборы правил, исключая шаблон
    var existingRulesets = document.querySelectorAll('.rule-set:not(#rule-set-template)');
    var newIndex = existingRulesets.length;

    // Клонируем шаблон
    var template = document.querySelector('#rule-set-template').cloneNode(true);
    template.id = '';
    template.style.display = 'block';

    // Заменяем INDEX на новый индекс во всех элементах
    template.innerHTML = template.innerHTML.replace(/\[INDEX\]/g, '[' + newIndex + ']');
    template.innerHTML = template.innerHTML.replace('INDEX', newIndex + 1);

    // Очищаем выбранные значения в select
    template.querySelectorAll('select').forEach(function(select) {
        Array.from(select.options).forEach(option => option.selected = false);
    });

    // Добавляем обработчик для кнопки удаления
    var deleteButton = template.querySelector('.delete-rule-set');
    if (deleteButton) {
        deleteButton.onclick = function(e) {
            e.preventDefault();
            removeRuleSet(this);
            return false;
        };
    }

    // Добавляем новый набор перед кнопкой добавления
    rulesets.appendChild(template);
}

function removeRuleSet(element) {
    if (confirm(deleteConfirmMessage)) {
        var fieldset = element.closest('.rule-set');
        if (fieldset) {
            fieldset.remove();

            // Обновляем индексы оставшихся наборов
            document.querySelectorAll('.rule-set:not(#rule-set-template)').forEach(function(fieldset, index) {
                // Обновляем номер в заголовке
                var legend = fieldset.querySelector('.group-label');
                if (legend) {
                    legend.textContent = legend.textContent.replace(/\d+/, index + 1);
                }

                // Обновляем name атрибуты всех select
                fieldset.querySelectorAll('select').forEach(function(select) {
                    select.name = select.name.replace(/\[(\d+)\]/, '[' + index + ']');
                });
            });
        }
    }
    return false;
}

// Глобальная переменная для текста подтверждения удаления
var deleteConfirmMessage = 'Вы уверены, что хотите удалить этот набор правил?';

// Инициализация при загрузке страницы
document.addEventListener('DOMContentLoaded', function() {
    // Настраиваем обработчик для кнопки добавления
    var addButton = document.querySelector('.add-rule-set');
    if (addButton) {
        addButton.onclick = function(e) {
            e.preventDefault();
            addRuleSet();
            return false;
        };
    }

    // Настраиваем обработчики для существующих кнопок удаления
    document.querySelectorAll('.delete-rule-set').forEach(function(button) {
        button.onclick = function(e) {
            e.preventDefault();
            removeRuleSet(this);
            return false;
        };
    });

    // Если нет наборов правил, создаем первый
    var existingRulesets = document.querySelectorAll('.rule-set:not(#rule-set-template)');
    if (existingRulesets.length === 0) {
        addRuleSet();
    }
});
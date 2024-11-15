# lib/neural_responsible/issue_patch.rb
module NeuralResponsible
  module IssuePatch
    def self.included(base)
      base.class_eval do
        after_save :set_neural_responsible

        private

        def set_neural_responsible
          return if neural_responsible_processed?
          return unless project.module_enabled?(:neural_responsible)
          return unless should_set_neural_responsible?

          Rails.logger.info "Starting neural prediction for issue ##{id}"

          # Помечаем, что обработка началась
          @neural_responsible_processed = true

          # Объединяем тему и описание для анализа
          text_for_analysis = [subject, description].compact.join("\n").strip
          Rails.logger.info "Text for analysis: #{text_for_analysis}"

          return if text_for_analysis.blank?

          result = RemoteService.predict(text_for_analysis)
          return unless result && result[:responsible]

          predicted_name = result[:responsible]
          Rails.logger.info "Predicted name: #{predicted_name.inspect}"

          user = User.find_by("CONCAT(lastname, ' ', firstname) = ?", predicted_name)
          Rails.logger.info "Found user: #{user&.inspect}"
          return unless user

          # Определяем способ назначения
          settings = Setting.plugin_neural_responsible
          assignment_type = settings['assignment_type'] || 'assigned_to'

          Rails.logger.info "Assignment type: #{assignment_type}"

          # Создаем комментарий с вероятностями
          if result[:probabilities].present?
            comment_text = "Нейросеть определила вероятности назначения:\n\n"
            result[:probabilities].each do |name, probability|
              percentage = (probability * 100).round(2)
              comment_text += "* #{name}: #{percentage}%\n"
            end

            # Получаем автора комментария из настроек или используем Anonymous
            comment_author_id = settings['comment_author_id'].presence
            comment_author = comment_author_id ? User.find_by(id: comment_author_id) : User.anonymous

            # Создаем журнальную запись (комментарий)
            journals.create!(
              user: comment_author,
              notes: comment_text,
              private_notes: true
            )
          end

          case assignment_type
          when 'assigned_to'
            Rails.logger.info "Assigning to user via assigned_to"
            update_column(:assigned_to_id, user.id)
          when 'custom_field'
            custom_field_id = settings['custom_field_id'].presence
            Rails.logger.info "Assigning to user via custom field #{custom_field_id}"
            return unless custom_field_id

            custom_value = custom_values.find_or_initialize_by(custom_field_id: custom_field_id)
            custom_value.value = user.id.to_s
            custom_value.save
          end

          Rails.logger.info "Neural assignment completed for issue ##{id}"
        end

        def neural_responsible_processed?
          @neural_responsible_processed == true
        end

        def should_set_neural_responsible?
          rule_sets = Setting.plugin_neural_responsible['rule_sets'] || {}

          rule_sets.values.any? do |rule_set|
            matches_rule_set?(rule_set)
          end
        end

        def matches_rule_set?(rule_set)
          return false unless rule_set.is_a?(Hash)
          return false unless rule_set['trackers']&.include?(tracker_id.to_s)

          if status_id_changed?
            return false unless rule_set['status_from'].to_a.include?(status_id_was.to_s)
            return false unless rule_set['status_to'].to_a.include?(status_id.to_s)
          end

          if assigned_to
            assignee_role_ids = assigned_to.roles_for_project(project).map(&:id).map(&:to_s)
            return false unless (rule_set['assignee_roles'].to_a & assignee_role_ids).any?
          end

          if User.current
            user_role_ids = User.current.roles_for_project(project).map(&:id).map(&:to_s)
            return false unless (rule_set['user_roles'].to_a & user_role_ids).any?
          end

          true
        end
      end
    end
  end
end
Issue.send(:include, NeuralResponsible::IssuePatch)
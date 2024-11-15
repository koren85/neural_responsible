module NeuralResponsible
  module ProjectPatch
    def self.included(base)
      base.class_eval do
        safe_attributes 'neural_responsible_enabled'
      end
    end
  end
end

Project.send(:include, NeuralResponsible::ProjectPatch)
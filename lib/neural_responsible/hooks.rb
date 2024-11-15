module NeuralResponsible
  class Hooks < Redmine::Hook::ViewListener
    def view_layouts_base_html_head(context={})
      stylesheet_link_tag('neural_responsible', plugin: 'neural_responsible') +
        javascript_include_tag('neural_responsible', plugin: 'neural_responsible')
    end
  end
end

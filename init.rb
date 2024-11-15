# init.rb
require 'redmine'
begin
  require 'active_resource'
rescue LoadError
  raise "Please install activeresource gem: gem install activeresource"
end

require_dependency 'neural_responsible/remote_service'
require_dependency 'neural_responsible/issue_patch'
require_dependency 'neural_responsible/project_patch'

Redmine::Plugin.register :neural_responsible do
  name 'Neural Responsible Plugin'
  author 'Your Name'
  description 'Automatically assigns responsible person based on neural network predictions'
  version '0.0.1'

  settings default: {
    'service_url' => 'http://195.19.103.105:5000/predict',
    'assignment_type' => 'assigned_to',
    'custom_field_id' => nil,
    'comment_author_id' => nil,
    'rule_sets' => {}
  }, partial: 'settings/neural_responsible_settings'

  project_module :neural_responsible do
    permission :use_neural_responsible, {}
  end
end

Rails.application.config.after_initialize do
  require_dependency 'neural_responsible/hooks'
end
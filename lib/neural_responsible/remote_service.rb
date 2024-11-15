# lib/neural_responsible/remote_service.rb
require 'active_resource'

module NeuralResponsible
  class RemoteService < ActiveResource::Base
    self.format = :json
    self.include_root_in_json = false

    def self.predict(text)
      begin
        service_url = Setting.plugin_neural_responsible['service_url']
        unless service_url.present?
          Rails.logger.error "Neural service URL is not configured"
          return nil
        end

        # Устанавливаем базовый URL
        uri = URI.parse(service_url)
        self.site = "#{uri.scheme}://#{uri.host}:#{uri.port}"

        Rails.logger.info "Sending request to neural service: #{service_url}"
        Rails.logger.info "Request body: #{{text: text}.to_json}"

        # Используем правильный путь для predict
        response = connection.post('/predict', {text: text}.to_json, {'Content-Type' => 'application/json'})

        if response.code.to_i == 200
          result = JSON.parse(response.body)
          Rails.logger.info "Neural service response: #{result.inspect}"
          {
            responsible: result['responsible'],
            probabilities: result['probabilities']
          }
        else
          Rails.logger.error "Neural service HTTP error: #{response.code} - #{response.message}"
          Rails.logger.error "Response body: #{response.body}"
          nil
        end
      rescue ActiveResource::ResourceNotFound => e
        Rails.logger.error "Neural service not found: #{e.message}"
        Rails.logger.error "URL: #{service_url}"
        Rails.logger.error "Site: #{site}"
        nil
      rescue => e
        Rails.logger.error "Neural service unexpected error: #{e.class} - #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        nil
      end
    end
  end
end
module Api
  class BaseController < ApplicationController
    include ActionController::HttpAuthentication::Token::ControllerMethods

    DEFAULT_LIMIT = 50
    MAX_LIMIT = 100

    before_action :authenticate

    rescue_from ActiveRecord::RecordNotFound do
      render json: { error: "not found" }, status: :not_found
    end

    rescue_from ActionController::ParameterMissing, ArgumentError do |error|
      render json: { error: error.message }, status: :bad_request
    end

    private

    def authenticate
      expected = Rails.configuration.x.admin_token.to_s
      authenticate_or_request_with_http_token do |token, _options|
        expected.present? && ActiveSupport::SecurityUtils.secure_compare(token, expected)
      end
    end

    # Keyset pagination on id, newest first: stable while new rows arrive.
    def render_page(scope)
      limit = params.fetch(:limit, DEFAULT_LIMIT).to_i.clamp(1, MAX_LIMIT)
      scope = scope.where(id: ...Integer(params[:before])) if params[:before].present?
      records = scope.reorder(id: :desc).limit(limit + 1).to_a
      next_cursor = records.size > limit ? records[limit - 1].id : nil

      render json: { data: records.first(limit).map { |record| yield record }, next_cursor: }
    end

    def render_errors(record)
      render json: { errors: record.errors.full_messages }, status: :unprocessable_content
    end
  end
end

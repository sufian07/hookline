module Api
  class BaseController < ApplicationController
    include ActionController::HttpAuthentication::Token::ControllerMethods

    DEFAULT_LIMIT = 50
    MAX_LIMIT = 100

    rate_limit to: RateLimits::API_PER_MINUTE, within: 1.minute, name: "api", store: RateLimits.store,
               by: -> { RateLimits.key_for(request.authorization) },
               with: -> { render json: { error: "rate limit exceeded" }, status: :too_many_requests }

    before_action :authenticate
    before_action :require_admin_for_writes

    rescue_from ActiveRecord::RecordNotFound do
      render json: { error: "not found" }, status: :not_found
    end

    rescue_from ActionController::ParameterMissing, ArgumentError do |error|
      render json: { error: error.message }, status: :bad_request
    end

    private

    attr_reader :role

    def authenticate
      @role = authenticate_or_request_with_http_token { |token, _options| AccessRole.for(token) }
    end

    # Reads are open to every role; anything that changes state needs the admin token.
    def require_admin_for_writes
      return if request.get? || request.head? || role == :admin

      render json: { error: "this token is read-only" }, status: :forbidden
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

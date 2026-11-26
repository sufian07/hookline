module Api
  class EventsController < BaseController
    def index
      scope = Event.all
      scope = scope.where(source_id: params[:source_id]) if params[:source_id].present?
      scope = scope.where(event_type: params[:event_type]) if params[:event_type].present?

      render_page(scope) { |event| Serializers.event(event) }
    end

    def show
      event = Event.includes(deliveries: :delivery_attempts).find(params[:id])

      render json: Serializers.event_detail(event)
    end
  end
end

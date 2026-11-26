module Api
  class DeliveriesController < BaseController
    def index
      scope = Delivery.all
      if params[:status].present?
        raise ArgumentError, "unknown status" unless Delivery::STATUSES.include?(params[:status])

        scope = scope.where(status: params[:status])
      end
      scope = scope.where(subscription_id: params[:subscription_id]) if params[:subscription_id].present?

      render_page(scope) { |delivery| Serializers.delivery(delivery) }
    end

    def replay
      delivery = Delivery.find(params[:id])
      unless delivery.replay
        return render json: { error: "only dead or delivered deliveries can be replayed" }, status: :conflict
      end

      DeliverJob.perform_later(delivery.id)
      render json: Serializers.delivery(delivery), status: :accepted
    end
  end
end

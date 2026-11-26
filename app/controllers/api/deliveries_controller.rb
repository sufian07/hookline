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
  end
end

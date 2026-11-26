module Api
  class SubscriptionsController < BaseController
    def index
      render_page(Source.find(params[:source_id]).subscriptions) { |subscription| Serializers.subscription(subscription) }
    end

    def create
      subscription = Source.find(params[:source_id]).subscriptions.new(params.permit(:url, :event_filter))
      return render_errors(subscription) unless subscription.save

      render json: Serializers.subscription(subscription).merge(signing_secret: subscription.signing_secret),
             status: :created
    end

    def update
      subscription = Subscription.find(params[:id])
      return render_errors(subscription) unless subscription.update(params.permit(:url, :event_filter, :active))

      render json: Serializers.subscription(subscription)
    end
  end
end

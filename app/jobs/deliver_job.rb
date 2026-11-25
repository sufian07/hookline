class DeliverJob < ApplicationJob
  def perform(delivery_id)
    delivery = Delivery.find_by(id: delivery_id)
    DeliveryRunner.new.call(delivery) if delivery
  end
end

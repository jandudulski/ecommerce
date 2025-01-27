require_relative "../../ordering/lib/ordering"
require_relative "../../pricing/lib/pricing"
require_relative "../../product_catalog/lib/product_catalog"
require_relative "../../crm/lib/crm"
require_relative "../../payments/lib/payments"
require_relative "../../inventory/lib/inventory"
require_relative "../../shipping/lib/shipping"
require_relative 'processes/check_availability_on_order_item_added_to_basket'
require_relative 'processes/order_confirmation'
require_relative 'processes/release_payment_process'
require_relative 'processes/shipment_process'

module Processes
  class Configuration
    def call(cqrs)
      enable_pricing_sync_from_ordering(cqrs)
      calculate_total_value_when_order_submitted(cqrs)
      notify_payments_about_order_total_value(cqrs)
      enable_inventory_sync_from_ordering(cqrs)
      enable_shipment_sync(cqrs)
      check_product_availability_on_adding_item_to_basket(cqrs)

      enable_release_payment_process(cqrs)
      enable_order_confirmation_process(cqrs)
      enable_shipment_process(cqrs)
    end

    private

    def enable_shipment_process(cqrs)
      cqrs.subscribe(
        ShipmentProcess.new(cqrs),
        [
          Shipping::ShippingAddressAddedToShipment,
          Shipping::ShipmentSubmitted,
          Ordering::OrderSubmitted,
          Ordering::OrderPaid
        ]
      )
    end

    def enable_shipment_sync(cqrs)
      cqrs.subscribe(
        ->(event) do
          cqrs.run(
            Shipping::AddItemToShipmentPickingList.new(
              order_id: event.data.fetch(:order_id),
              product_id: event.data.fetch(:product_id)
            )
          )
        end,
        [Ordering::ItemAddedToBasket]
      )
      cqrs.subscribe(
        ->(event) do
          cqrs.run(
            Shipping::RemoveItemFromShipmentPickingList.new(
              order_id: event.data.fetch(:order_id),
              product_id: event.data.fetch(:product_id)
            )
          )
        end,
        [Ordering::ItemRemovedFromBasket]
      )
    end

    def notify_payments_about_order_total_value(cqrs)
      cqrs.subscribe(
        ->(event) do
          cqrs.run(
            Payments::SetPaymentAmount.new(
              order_id: event.data.fetch(:order_id),
              amount: event.data.fetch(:discounted_amount).to_f
            )
          )
        end,
        [Pricing::OrderTotalValueCalculated]
      )
    end

    def calculate_total_value_when_order_submitted(cqrs)
      cqrs.subscribe(
        ->(event) do
          cqrs.run(
            Pricing::CalculateTotalValue.new(
              order_id: event.data.fetch(:order_id)
            )
          )
        end,
        [Ordering::OrderSubmitted]
      )
    end

    def enable_inventory_sync_from_ordering(cqrs)
      cqrs.subscribe(
        ->(event) do
          cqrs.run(
            Inventory::SubmitReservation.new(
              order_id: event.data.fetch(:order_id),
              reservation_items: event.data.fetch(:order_lines)
            )
          )
        end,
        [Ordering::OrderSubmitted]
      )

      cqrs.subscribe(
        ->(event) do
          cqrs.run(
            Inventory::CompleteReservation.new(
              order_id: event.data.fetch(:order_id)
            )
          )
        end,
        [Ordering::OrderPaid]
      )

      cqrs.subscribe(
        ->(event) do
          cqrs.run(
            Inventory::CancelReservation.new(
              order_id: event.data.fetch(:order_id)
            )
          )
        end,
        [Ordering::OrderCancelled, Ordering::OrderExpired]
      )
    end

    def enable_pricing_sync_from_ordering(cqrs)
      cqrs.subscribe(
        ->(event) do
          cqrs.run(
            Pricing::AddPriceItem.new(
              order_id: event.data.fetch(:order_id),
              product_id: event.data.fetch(:product_id)
            )
          )
        end,
        [Ordering::ItemAddedToBasket]
      )

      cqrs.subscribe(
        ->(event) do
          cqrs.run(
            Pricing::RemovePriceItem.new(
              order_id: event.data.fetch(:order_id),
              product_id: event.data.fetch(:product_id)
            )
          )
        end,
        [Ordering::ItemRemovedFromBasket]
      )
    end

    def enable_order_confirmation_process(cqrs)
      cqrs.subscribe(
        OrderConfirmation.new(cqrs),
        [Payments::PaymentAuthorized, Payments::PaymentCaptured]
      )
    end

    def enable_release_payment_process(cqrs)
      cqrs.subscribe(
        ReleasePaymentProcess.new(cqrs),
        [
          Ordering::OrderSubmitted,
          Ordering::OrderExpired,
          Ordering::OrderPaid,
          Payments::PaymentAuthorized,
          Payments::PaymentReleased
        ]
      )
    end

    def check_product_availability_on_adding_item_to_basket(cqrs)
      cqrs.subscribe(
        CheckAvailabilityOnOrderItemAddedToBasket.new(cqrs),
        [Ordering::ItemAddedToBasket]
      )
    end
  end
end
require "infra"
require_relative "shipping/commands/add_item_to_shipment_picking_list"
require_relative "shipping/events/item_added_to_shipment_picking_list"
require_relative "shipping/services/on_add_item_to_shipment_picking_list"

require_relative "shipping/commands/remove_item_from_shipment_picking_list"
require_relative "shipping/events/item_removed_from_shipment_picking_list"
require_relative "shipping/services/on_remove_item_from_shipment_picking_list"

require_relative "shipping/commands/add_shipping_address_to_shipment"
require_relative "shipping/events/shipping_address_added_to_shipment"
require_relative "shipping/services/on_add_shipping_address_to_shipment"

require_relative "shipping/commands/submit_shipment"
require_relative "shipping/events/shipment_submitted"
require_relative "shipping/services/on_submit_shipment"

require_relative "shipping/commands/authorize_shipment"
require_relative "shipping/events/shipment_authorized"
require_relative "shipping/services/on_authorize_shipment"

require_relative "shipping/shipment"
require_relative "shipping/picking_list"
require_relative "shipping/picking_list_item"
require_relative "shipping/postal_address"

module Shipping
  class Configuration
    def call(cqrs)
      cqrs.register(
        AddItemToShipmentPickingList,
        OnAddItemToShipmentPickingList.new(cqrs.event_store)
      )
      cqrs.register(
        RemoveItemFromShipmentPickingList,
        OnRemoveItemFromShipmentPickingList.new(cqrs.event_store)
      )
      cqrs.register(
        AddShippingAddressToShipment,
        OnAddShippingAddressToShipment.new(cqrs.event_store)
      )
      cqrs.register(
        SubmitShipment,
        OnSubmitShipment.new(cqrs.event_store)
      )
      cqrs.register(
        AuthorizeShipment,
        OnAuthorizeShipment.new(cqrs.event_store)
      )
    end
  end
end
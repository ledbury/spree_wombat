require 'active_model/serializer'

module Spree
  module Wombat
    class ShipmentSerializer < ActiveModel::Serializer
      attributes :id, :order_id, :email, :cost, :status, :stock_location,
                :shipping_method, :tracking, :placed_on, :shipped_at, :totals,
                :updated_at, :channel, :items, :ship_to, :bill_to, :billing_address,
                :shipping_address

      #has_one :bill_to, serializer: AddressSerializer, root: "billing_address"
      #has_one :ship_to, serializer: AddressSerializer, root: "shipping_address"
      #has_many :bill_to, serializer: AddressSerializer, root: "billing_address"
      #has_many :ship_to, serializer: AddressSerializer, root: "shipping_address"

      def billing_address
        Spree::Wombat::AddressSerializer.new(object.order.bill_address)
      end

      def shipping_address
        Spree::Wombat::AddressSerializer.new(object.order.ship_address)
      end

      def id
        object.number
      end

      def order_id
        object.order.number
      end

      def email
        object.order.email
      end

      def channel
        object.order.channel || 'spree'
      end

      def cost
        object.cost.to_f
      end

      def status
        object.state
      end

      def stock_location
        object.stock_location.name
      end

      def shipping_method
        object.shipping_method.try(:name)
      end

      def placed_on
        if object.order.completed_at?
          object.order.completed_at.getutc.try(:iso8601)
        else
          ''
        end
      end

      def shipped_at
        object.shipped_at.try(:iso8601)
      end

      def totals
        {
          item: object.order.item_total.to_f,
          adjustment: adjustment_total,
          tax: tax_total,
          shipping: shipping_total,
          payment: object.order.payments.completed.sum(:amount).to_f,
          order: object.order.total.to_f
        }
      end

      def updated_at
        object.updated_at.iso8601
      end

      def items
        object.inventory_units
      end

      include Spree::Wombat::JsonFromAttributes

      private

        def adjustment_total
          object.order.adjustment_total.to_f
        end

        def shipping_total
          object.order.shipment_total.to_f
        end

        def tax_total
          (object.order.included_tax_total + object.order.additional_tax_total).to_f
        end

    end
  end
end

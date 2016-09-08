require 'active_model/serializer'

module Ledbury
  module Pipeline
    class OrderSerializer < ActiveModel::Serializer
      include SimpleStructuredLogger

      attributes :status,
        :po_number,
        :channel,
        :email,
        # :currency,
        :placed_on,
        :updated_at,
        :created_at,
        :totals,
        :adjustments,
        # :guest_token,
        # :shipping_instructions,
        :payment,
        :metadata,
        :items,
        :netsuite_customer_id,
        :shipping_method,
        :discounts,
        :gift_cards

      # has_many :line_items, serializer: Spree::Wombat::LineItemSerializer, key: 'items'
      # has_many :payments, serializer: Spree::Wombat::PaymentSerializer

      has_one :shipping_address, serializer: Ledbury::Pipeline::AddressSerializer
      has_one :billing_address, serializer: Ledbury::Pipeline::AddressSerializer

      def po_number
        object.number
      end

      def gift_cards
        cards = object.adjustments.store_credits.map do |store_credit|
          {
            code: store_credit.source.code,
            amount: store_credit.amount.to_f * -1
          }
        end

        cards += object.adjustments.gift_card.map do |gift_card|
          {
            code: gift_card.source.code,
            amount: gift_card.amount.to_f * -1
          }
        end

        cards
      end

      def discounts
        object.
          all_adjustments.
          eligible.
          non_store_credit.
          non_gift_card.
          credit.
          non_return_authorization.
          map do |discount|
            # TODO move this to a scope
            next if discount.source.is_a?(Spree::SalePriceHandler)

            {
              # type: '',
              description: discount.label,
              amount: discount.amount.to_f
            }
          end
      end

      def netsuite_customer_id
        object.user.netsuite_customer_id
      end

      # https://ledbury.slack.com/archives/pipeline/p1473284514000109
      def shipping_method
        if object.shipping_method.is_ship_to_store?
          'In-Store Pickup'
        else
          object.shipping_method.name
        end
      end

      def items
        # NOTE tailoring is handled as a adjustment

        object.line_items.non_gift_box.map do |line_item|
          if line_item.is_physical_gift_card?
            next {
              "product_id" => line_item.variant.sku,
              "quantity" => line_item.quantity,
              "total" => line_item.sale_price,
              "netsuite_id" => line_item.variant.netsuite_item_id,

              "gift_card" => true,
              "gift_card_code" => line_item.gift_card.code,
              "gift_card_amount" => line_item.price
            }
          end

          # TODO handle egift cards

          {
            "product_id" => line_item.variant.sku,
            "quantity" => line_item.quantity,
            "gift_box" => line_item.attached_line_items.present?,
            "tailoring" => if line_item.has_alteration?
              line_item.alterations.first.degree
            end,
            # "total" => line_item.final_amount,
            "total" => line_item.sale_price,
            "netsuite_id" => line_item.variant.netsuite_item_id
          }
        end
      end

      def payment
        if object.payments.size > 1
          log.error 'order contains more than one payment', order_id: object.id
        end

        spree_payment = object.payments.first

        # https://ledbury.slack.com/archives/pipeline/p1473283254000087
        if spree_payment.source.blank?
          log.info 'paid with gift card'

          return { type: 'gift_card' }
        end

        card_type = spree_payment.source.cc_type
        auth_code = spree_payment.identifier

        response_code = if spree_payment.response_code.count(';') == 2
          spree_payment.response_code.split(";")[1]
        else
          fail "unexpected payment response encountered"
        end

        # https://ledbury.slack.com/archives/pipeline/p1473252271000002
        {
          # auth and response are needed for NS
          auth: auth_code,
          response: response_code,
          type: card_type
        }
      end

      def metadata
        {
          netsuite_employee_id: object.user.netsuite_employee_id,
          klass: object.classification,
          department: object.department
        }
      end

      def status
        object.state
      end

      def channel
        object.channel || 'spree'
      end

      def updated_at
        object.updated_at.getutc.try(:iso8601)
      end

      def placed_on
        if object.completed_at?
          object.completed_at.getutc.try(:iso8601)
        else
          ''
        end
      end

      def totals
        {
          item: object.item_total.to_f,
          # adjustment: adjustment_total,
          tax: tax_total,
          shipping: shipping_total,
          payment: object.payments.completed.sum(:amount).to_f,
          total: object.total.to_f
        }
      end

      def adjustments
        [
          {
            name: 'discount',
            value: object.all_adjustments.eligible.non_store_credit.credit.map(&:amount).sum.to_f,
          },
          { name: 'tax', value: tax_total },
          { name: 'shipping', value: shipping_total }
        ]
      end

      private

        def adjustment_total
          object.adjustment_total.to_f
        end

        def shipping_total
          object.shipment_total.to_f
        end

        def tax_total
          tax = 0.0
          tax_rate_taxes = (object.included_tax_total + object.additional_tax_total).to_f
          manual_import_adjustment_tax_adjustments = object.adjustments.select{|adjustment| adjustment.label.downcase == "tax" && adjustment.source_id == nil && adjustment.source_type == nil}
          if(tax_rate_taxes == 0.0 && manual_import_adjustment_tax_adjustments.present?)
            tax = manual_import_adjustment_tax_adjustments.sum(&:amount).to_f
          else
            tax = tax_rate_taxes
          end
          tax
        end

    end
  end
end

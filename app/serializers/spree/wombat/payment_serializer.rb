require 'active_model/serializer'

module Spree
  module Wombat
    class PaymentSerializer < ActiveModel::Serializer
      attributes :id, :number, :status, :amount, :payment_method

      def number
        object.identifier
      end

      def payment_method
        if object.payment_method
          object.payment_method.name
        end
      end

      def status
        object.state
      end

      def amount
        object.amount.to_f
      end

      include Spree::Wombat::JsonFromAttributes
    end
  end
end

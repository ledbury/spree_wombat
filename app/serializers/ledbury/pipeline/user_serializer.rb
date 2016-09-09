# NOTE this does not exist in Wombat core

module Ledbury
  module Pipeline
    class UserSerializer < ActiveModel::Serializer
      attributes :firstname, :lastname, :email, :lead_source,
                 :id, :internal_id

      has_one :ship_address, key: :shipping_address, serializer: Ledbury::Pipeline::AddressSerializer
      has_one :bill_address, key: :billing_address, serializer: Ledbury::Pipeline::AddressSerializer

      def lead_source
        object.questionnaire.try(:answer)
      end

      # TODO consider migrating netsuite_customer_id => internal_id / netsuite_id for uniformity across all records
      def internal_id
        object.netsuite_customer_id
      end

      # NOTE often the first, last, bill address, and shipping address are not
      #      set on the user. The logic below pulls these values from the last order
      #      if they are not on the user model.

      def firstname
        if (name = object.firstname).present?
          return name
        end

        last_order.ship_address.firstname
      end

      def lastname
        if (name = object.lastname).present?
          return name
        end

        last_order.bill_address.lastname
      end

      def ship_address
        if address = object.ship_address
          return address
        end

        last_order.ship_address
      end

      def bill_address
        if address = object.bill_address
          return address
        end

        last_order.bill_address
      end

      protected

        def last_order
          @last_order ||= object.orders.complete.last
        end
    end
  end
end

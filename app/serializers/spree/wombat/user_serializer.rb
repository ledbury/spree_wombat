# NOTE this does not exist in Wombat core

module Spree
  module Wombat
    class UserSerializer < ActiveModel::Serializer
      attributes :firstname, :lastname, :email, :lead_source,
                 :id, :internal_id

      has_one :ship_address, key: :shipping_address, serializer: Spree::Wombat::AddressSerializer
      has_one :bill_address, key: :billing_address, serializer: Spree::Wombat::AddressSerializer

      def lead_source
        object.questionnaire.try(:answer)
      end

      # TODO consider migrating netsuite_customer_id => internal_id / netsuite_id for uniformity across all records
      def internal_id
        object.netsuite_customer_id
      end
    end
  end
end

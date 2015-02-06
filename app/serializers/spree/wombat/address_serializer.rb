require 'active_model/serializer'

module Spree
  module Wombat
    class AddressSerializer < ActiveModel::Serializer
      attributes :firstname, :lastname, :address1, :address2, :zipcode, :city,
                 :state , :phone, :country

      def country
        if object
          if object.country
            object.country.iso
          end
        end
      end

      def state
        if object
          if object.state
            object.state.abbr
          else
            object.state_name
          end
        end
      end

      include Spree::Wombat::JsonFromAttributes

    end
  end
end

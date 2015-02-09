require 'active_model/serializer'

module Spree
  module Wombat
    class LineItemSerializer < ActiveModel::Serializer
      attributes :id, :product_id, :name, :quantity, :price

      def name
        if object.variant
          object.variant.name
        end
      end

      def product_id
        if object.variant
          object.variant.sku
        end
      end

      def price
        object.price.to_f
      end

      include Spree::Wombat::JsonFromAttributes
    end
  end
end

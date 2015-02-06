require 'active_model/serializer'

module Spree
  module Wombat
    class VariantSerializer < ActiveModel::Serializer

      attributes :sku, :price, :cost_price, :options, :images
      has_many :images

      def images
        ActiveModel::Serializer::ArraySerializer.new(
          object.images,
          serializer: Spree::Wombat::ImageSerializer,
          root: false
        )
      end

      def price
        object.price.to_f
      end

      def cost_price
        object.cost_price.to_f
      end

      def options
        object.option_values.each_with_object({}) {|ov,h| h[ov.option_type.presentation]= ov.presentation}
      end

      include Spree::Wombat::JsonFromAttributes
    end
  end
end

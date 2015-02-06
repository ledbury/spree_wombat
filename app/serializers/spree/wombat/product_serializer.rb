require 'active_model_serializers'

module Spree
  module Wombat
    class ProductSerializer < ActiveModel::Serializer

      attributes :id, :name, :sku, :description, :price, :cost_price,
                 :available_on, :permalink, :meta_description, :meta_keywords,
                 :shipping_category, :taxons, :options, :variants, :images

      has_many :images
      has_many :variants

      def images
        ActiveModel::Serializer::ArraySerializer.new(
          object.images,
          serializer: Spree::Wombat::ImageSerializer,
          root: false
        )
      end

      def variants
        variants_array = (object.variants.blank?) ? [object.master] : object.variants
        ActiveModel::Serializer::ArraySerializer.new(
            variants_array,
            serializer: Spree::Wombat::VariantSerializer,
            root: false
          )
      end

      def id
        object.sku
      end

      def price
        object.price.to_f
      end

      def cost_price
        object.cost_price.to_f
      end

      def available_on
        object.available_on.try(:iso8601)
      end

      def permalink
        object.slug
      end

      def shipping_category
        object.shipping_category.name
      end

      def taxons
        object.taxons.collect {|t| t.self_and_ancestors.collect(&:name)}
      end

      def options
        object.option_types.pluck(:name)
      end

    include Spree::Wombat::JsonFromAttributes
    end
  end
end

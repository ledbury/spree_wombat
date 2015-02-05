require 'active_model/serializer'

module Spree
  module Wombat
    class ResponderSerializer < ActiveModel::Serializer
      attributes :request_id, :summary, :objects, :backtrace

      def filter(keys)
        keys.delete(:backtrace) unless object.backtrace.present?
        keys.delete(:objects) unless object.objects.present?
        keys
      end

      def attributes
        hash = super
        if objects = hash.delete(:objects)
          objects.each do |key, values|
            hash[key] = values
          end
        end
        hash
      end

      include Spree::Wombat::JsonFromAttributes
    end
  end
end

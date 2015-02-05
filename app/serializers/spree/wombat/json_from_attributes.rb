require 'pry'

module Spree
  module Wombat
    module JsonFromAttributes
      def to_json
        attr_json = []
        attributes.each do |key, value|
          if value
            attr_json << normalized(key, value)
          end
        end
        "{#{attr_json.join(',')}}"
      end

      private

      def has_serializer?(object)
        if object.respond_to? :each
          "Spree::Wombat::#{object.first.class.name.split('::').last}Serializer".safe_constantize
        else
          "Spree::Wombat::#{object.class.name.split('::').last}Serializer".safe_constantize
        end
      end

      def normalized(key, value)
        if value.respond_to? :each
          normalized_value = serialize_arr(value, key)
        else
          normalized_value = value.to_json
        end

        "\"#{key}\":#{normalized_value}"
      end

      def serialize_arr(array, key)
        if (key.to_s == 'variant')
          binding.pry
        end
        unless array.blank?
          serializer_class = has_serializer?(array)
          if serializer_class
            if array.respond_to? :keys
              prefix, sufix = '{','}'
            else
              prefix, sufix = '[',']'
            end
            result = [].tap do |result_array|
              array.each do |element|
                result_array << serializer_class.new(element)
              end
            end
            "#{prefix}#{result.map{|result_element| result_element.to_json}.join(',')}#{sufix}"
          else
            array.to_json
          end
        else
          array.to_json
        end

      end

      alias_method :to_json_custom,:to_json
    end
  end
end

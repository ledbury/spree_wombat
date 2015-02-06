module Spree
  module Wombat
    module JsonFromAttributes

      def to_json(*args)
        attr_json = []
        attributes.each do |key, value|
          if value
            unless(value.class == ActiveModel::Serializer::ArraySerializer)
              attr_json << "\"#{key}\":#{value.to_json}"
            else
              attr_json << "\"#{key}\":[#{value.map{|element| element.to_json}.join(',')}]"
            end
          end
        end
        "{#{attr_json.join(',')}}"
      end

    end
  end
end

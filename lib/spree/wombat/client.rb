require 'json'
require 'openssl'
require 'httparty'

module Spree
  module Wombat
    class Client

      def self.pull(object, last_poll_time)
        payload_builder = Spree::Wombat::Config[:payload_builder][object]

        model_name = payload_builder[:model].present? ? payload_builder[:model] : object

        scope = model_name.constantize

        if filter = payload_builder[:filter]
          scope = scope.send(filter.to_sym)
        end

        Rails.logger.info "initiating poll: last_poll=#{last_poll_time} now=#{Time.now} model=#{model_name}"

        serialized_collection = ActiveModel::Serializer::ArraySerializer.new(
          scope.where(updated_at: last_poll_time...Time.now),
          serializer: payload_builder[:serializer].constantize,
          root: payload_builder[:root]
        )

        serializer_adapter = ActiveModel::Serializer::Adapter.create(serialized_collection, adapter: :json)
      end
    end
  end
end

class PushApiError < StandardError; end

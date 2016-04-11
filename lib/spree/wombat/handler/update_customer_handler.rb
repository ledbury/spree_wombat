module Spree
  module Wombat
    module Handler
      class UpdateCustomerHandler < CustomerHandlerBase

        def process
          # http://stackoverflow.com/questions/861448/is-there-a-way-to-avoid-automatically-updating-rails-timestamp-fields
          ActiveRecord::Base.record_timestamps = false

          email = @payload["customer"]["email"]
          user_id = @payload["customer"]["id"]

          user = Spree.user_class.where(email: email).first
          user ||= Spree.user_class.find_by(id: user_id)

          return response("Can't find customer with email '#{email}' or ID '#{user_id}'", 500) unless user

          firstname = @payload["customer"]["firstname"]
          lastname = @payload["customer"]["lastname"]
          phone = @payload["customer"]["phone"]

          user.firstname = firstname
          user.lastname = lastname
          user.netsuite_customer_id = @payload["customer"]["internal_id"]

          begin
            if @payload["customer"]["shipping_address"]
              if user.ship_address
                user.ship_address.update_attributes(prepare_address(firstname, lastname, phone, @payload["customer"]["shipping_address"]))
              else
                user.ship_address = Spree::Address.create!(prepare_address(firstname, lastname, phone, @payload["customer"]["shipping_address"]))
              end
            end

            if @payload["customer"]["billing_address"]
              if user.bill_address
                user.bill_address.update_attributes(prepare_address(firstname, lastname, phone, @payload["customer"]["billing_address"]))
              else
                user.bill_address = Spree::Address.create!(prepare_address(firstname, lastname, phone, @payload["customer"]["billing_address"]))
              end
            end
          rescue Exception => exception
            return response(exception.message, 500)
          end

          user.save!

          response "Updated customer with #{email} and ID: #{user.id}"
        ensure
          ActiveRecord::Base.record_timestamps = true
        end

      end
    end
  end
end

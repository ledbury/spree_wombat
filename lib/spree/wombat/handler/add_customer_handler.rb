module Spree
  module Wombat
    module Handler
      class AddCustomerHandler < CustomerHandlerBase

        def process
          email = @payload["customer"]["email"]
          user_id = @payload["customer"]["id"]

          if Spree.user_class.find_by(email: email) || user_id.present?
            return Spree::Wombat::Handler::UpdateCustomerHandler.new(@payload).process
          end

          user = Spree.user_class.new(email: email)

          firstname = @payload["customer"]["firstname"]
          lastname = @payload["customer"]["lastname"]
          phone = @payload["customer"]["phone"]

          user.firstname = firstname
          user.lastname = lastname
          user.netsuite_customer_id = @payload["customer"]["internal_id"]

          user.save(validate: false)

          begin
            user.ship_address = Spree::Address.create!(prepare_address(firstname, lastname, phone, @payload["customer"]["shipping_address"]))
            user.bill_address = Spree::Address.create!(prepare_address(firstname, lastname, phone, @payload["customer"]["billing_address"]))
          rescue Exception => exception
            return response(exception.message, 200)
          end

          user.save

          response "Added new customer with #{email} and ID: #{user.id}"
        end

      end
    end
  end
end

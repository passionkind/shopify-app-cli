module ShopifyCli
  module Helpers
    class PkceToken
      class << self
        def read(ctx)
          store = Store.new
          store.get(:identity_exchange_token) do
            ShopifyCli::Tasks::AuthenticateIdentity.call(ctx)
            store.get(:identity_exchange_token)
          end
        end
      end
    end
  end
end

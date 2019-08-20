module ShopifyCli
  module Helpers
    class AccessToken
      class << self
        def read(ctx)
          store = Store.new
          store.get(:admin_access_token) do
            ShopifyCli::Tasks::AuthenticateShopify.call(ctx)
            store.get(:admin_access_token)
          end
        end
      end
    end
  end
end

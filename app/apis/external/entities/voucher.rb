module External
  module Entities
    class Voucher < Grape::Entity
      expose :denomination, :aliases, :applicable_store_name, :valid_from, :valid_till, :active?, :used_datetime
    end
  end
end
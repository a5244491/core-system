module Engine
  module POS
    module Entities
      class Receipt < Grape::Entity
        expose :transaction_type, :extra_rows, :extra_rows_m, :footer, :footer_m
      end
    end
  end
end
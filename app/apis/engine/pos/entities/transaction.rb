module Engine
  module POS
    module Entities
      class Transaction < Grape::Entity
        expose :actual_money_amount
        expose :merchant_rate, unless: lambda { |transaction, options| transaction.merchant_rate.blank?}
        expose :ref_id, as: :trans_id
        expose :payment_plan_id, as: :plan_id
        expose :receipt, using: Engine::POS::Entities::Receipt do |transaction, options|
            transaction.receipt
        end
      end
    end
  end
end
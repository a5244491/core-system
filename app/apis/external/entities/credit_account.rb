module External
  module Entities
    class CreditAccount < Grape::Entity
      expose :id, :external_id, :name, :address, :mobile, :total_credit, :usable_credit, :locked_credit, :cashed_credit, :referer_credit, :referee_credit, :consumption_credit, :consumption_times, :referer_account_id
    end
  end
end
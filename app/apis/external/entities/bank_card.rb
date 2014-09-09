module External
  module Entities
    class BankCard < Grape::Entity
      expose :id, :card_type, :bank_name, :cashing_card, :credit_earned, :created_at
    end
  end
end
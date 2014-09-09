module External
  module Entities
    class TransactionLog < Grape::Entity
      expose :log_type,
             :transaction_datetime,
             :transaction_type,
             :credit_delta,
             :customer_name,
             :merchant_name,
             :terminal_num,
             :media_num,
             :mobile,
             :sequence_number,
             :merchant_amount,
             :created_at,
             :matched_bank,
             :checked,
             :money_amount,
             :actual_money_amount,
             :merchant_amount,
             :voucher_used_count,
             :voucher_deducted_amount,
             :credit_account_id
      expose :id do |log|
         log.id[0]
      end
    end
  end
end
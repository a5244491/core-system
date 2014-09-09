module External
  module Entities
    class VoucherTransactionLog < Grape::Entity
      expose :issue_event,
             :transaction_datetime,
             :transaction_type,
             :denomination,
             :deducted_amount,
             :merchant_name,
             :issuer_type,
             :issuer_identifier,
             :issuer_name,
             :settler_type,
             :settler_identifier,
             :settler_name,
             :checked,
             :mobile,
             :voucher_meta_code
      expose :id do |log|
        log.id[0]
      end
    end
  end
end
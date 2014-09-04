json.records do
  json.array!  @transaction_logs do |log|
    json.extract! log,
                  :log_type,
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
    json.id log.id[0]
  end

end
json.total @total
json.sum @sum





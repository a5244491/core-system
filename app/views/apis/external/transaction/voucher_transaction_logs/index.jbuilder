json.records do
  json.array!  @voucher_transaction_logs do |log|
    json.extract! log,
                  :issue_event,
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
    json.id log.id[0]
  end
end
json.total @total
json.sum @sum





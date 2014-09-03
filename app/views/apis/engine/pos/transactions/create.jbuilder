json.extract! @transaction,:actual_money_amount, :trans_id, :plan_id
json.merchant_rate(@transaction.merchant_rate) unless @transaction.merchant_rate.blank?
json.receipt do
  json.extract! @transaction.to_receipt, :transaction_type, :extra_rows, :extra_rows_m, :footer, :footer_m
end
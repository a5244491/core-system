json.actual_money_amount @transaction.actual_money_amount
json.trans_id @transaction.ref_id
json.plan_id @transaction.payment_plan_id
json.merchant_rate(@transaction.merchant_rate) unless @transaction.merchant_rate.blank?
json.receipt do
  json.extract! @transaction.to_receipt, :transaction_type, :extra_rows, :extra_rows_m, :footer, :footer_m
end
json.receipt do
  json.extract! @receipt, :transaction_type, :extra_rows, :extra_rows_m, :footer, :footer_m
end
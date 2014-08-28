json.array!(@merchant_bank_discounts) do |merchant_bank_discount|
  json.extract! merchant_bank_discount, :id
  json.url merchant_bank_discount_url(merchant_bank_discount, format: :json)
end

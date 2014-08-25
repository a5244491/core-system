json.array!(@merchant_merchant_stores) do |merchant_merchant_store|
  json.extract! merchant_merchant_store, :id
  json.url merchant_merchant_store_url(merchant_merchant_store, format: :json)
end

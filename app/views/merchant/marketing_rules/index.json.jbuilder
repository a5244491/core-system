json.array!(@merchant_marketing_rules) do |merchant_marketing_rule|
  json.extract! merchant_marketing_rule, :id
  json.url merchant_marketing_rule_url(merchant_marketing_rule, format: :json)
end

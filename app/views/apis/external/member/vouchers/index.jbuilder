json.records do
  json.array! @vouchers do |voucher|
    json.extract! voucher, :denomination, :aliases, :applicable_store_name, :valid_from, :valid_till, :active?, :used_datetime
  end
end
json.total @total





json.records do
  json.array! @bank_cards, :id, :card_type, :bank_name, :cashing_card, :credit_earned, :created_at
end
json.total @total

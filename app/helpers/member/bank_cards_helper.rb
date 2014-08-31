module Member::BankCardsHelper
  cattr_accessor :bank_card_type_hash
  self.bank_card_type_hash = {
      1 => '借记卡',
      2 => '信用卡'
  }
end

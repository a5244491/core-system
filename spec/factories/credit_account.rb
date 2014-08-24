FactoryGirl.define do
  factory :individual_credit_account, class: Member::IndividualCreditAccount do
    mobile '123456'
    name 'test'
    address 'test'
    factory :individual_credit_account_with_bank_card do
      after(:create) do |credit_account|
        credit_account.add_bank_card('111111111111111111111', Member::BankCard::DEBIT_CARD, 'test_bank')
      end
    end
    factory :individual_credit_account_with_cashing_card do
       after(:create) do |credit_account|
         credit_account.add_bank_card('111111111111111111111', Member::BankCard::DEBIT_CARD, 'test_bank')
         credit_account.bank_cards.first.update_attributes(cashing_card: true)
       end
    end
  end
  factory :merchant_credit_account, class: Member::MerchantCreditAccount do
  end
end
FactoryGirl.define do
  factory :individual_credit_account, class: Member::IndividualCreditAccount do
    ignore do
      bank_card nil
      referer_mobile nil
    end
    mobile '123456'
    name 'test'
    address 'test'
    after(:create) do |credit_account, evaluator|
      credit_account.add_bank_card(evaluator.bank_card, Member::BankCard::DEBIT_CARD, 'test_bank') unless evaluator.bank_card.nil?
      unless evaluator.referer_mobile.nil?
        referer_account = Member::CreditAccount.where(mobile: evaluator.referer_mobile).first || create(:individual_credit_account, mobile: evaluator.referer_mobile)
        credit_account.referer_account = referer_account
        credit_account.save!
      end
    end
  end
  factory :merchant_credit_account, class: Member::MerchantCreditAccount do
  end
end
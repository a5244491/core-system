FactoryGirl.define do
  factory :marketing_rule do
    factory :bind_card_rule, class: Merchant::BindCardRule do
    end
    factory :register_rule, class: Merchant::RegisterRule do
    end
    factory :transaction_rule, class: Merchant::TransactionRule do
    end
  end
end
FactoryGirl.define do
  factory :marketing_rule do
    trait :valid do
      status Rule::ACTIVE
      valid_till 10.years.from_now
      valid_from 10.years.ago
    end
    factory :bind_card_rule, class: Merchant::BindCardRule do
    end
    factory :register_rule, class: Merchant::RegisterRule do
    end
    factory :transaction_rule, class: Merchant::TransactionRule do
    end
  end
end
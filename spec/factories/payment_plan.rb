FactoryGirl.define do
  factory :payment_plan do
    merchant_rate 0.03
    voucher_status Pay::PaymentPlan::ACCEPT_ALL
    status Pay::PaymentPlan::VALID
    trait :invalid do
      status Pay::PaymentPlan::INVALID
    end
    trait :rule_for_referee do
      user_type Pay::PaymentPlan::REFEREE
      user_tag { merchant_store.credit_account.external_id unless merchant_store.nil? }
    end
    trait :not_accept_voucher do
      voucher_status Pay::PaymentPlan::ACCEPT_NONE
    end

    trait :only_members do
      user_type Pay::PaymentPlan::MEMBERS
    end
    factory :bank_discount, class: Pay::BankDiscount do
      discount_rate 0.1
    end
    factory :credit_back, class: Pay::CreditBack, traits: [:only_members] do
      customer_rate 0.01

    end
    factory :none_payment_plan, class: Pay::NonePaymentPlan do
      merchant_rate nil
    end
  end
end
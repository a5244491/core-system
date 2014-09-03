FactoryGirl.define do
  factory :post_action do
    factory :voucher_action, class: Merchant::VoucherAction do
      voucher_count 1
    end
  end
end
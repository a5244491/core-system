FactoryGirl.define do
  factory :voucher_meta, class: Member::VoucherMeta do
    factory :active_voucher_meta do
      status Member::VoucherMeta::ACTIVE
      valid_till 10.years.from_now
      valid_from 10.years.ago
    end
    applicable_type Member::VoucherMeta::ALL_STORE
    ignore do
      store nil
      group nil
    end
    before :create do |voucher_meta, evaluator|
      if !evaluator.store.nil?
        voucher_meta.applicable_type = Member::VoucherMeta::SINGLE_STORE
        voucher_meta.merchant_store = evaluator.store
      elsif !evaluator.group.nil?
        voucher_meta.applicable_type = Member::VoucherMeta::STORE_GROUP
        voucher_meta.merchant_group = evaluator.group
      end
    end
  end
end
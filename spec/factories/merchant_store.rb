FactoryGirl.define do
  factory :merchant_store, class: Merchant::MerchantStore do
    ignore do
      usable_credit 0
      acquirer nil
    end
    name 'test'
    merchant_number '111'
    clearance_account_num '23123'
    clearance_account_bank 'test bank'
    clearance_account_name 'test name'
    standard_rate 0.01
    # status 'active'
    after :create do |store, evaluator|
      create(:merchant_credit_account, usable_credit: evaluator.usable_credit, merchant_store: store)
      unless evaluator.acquirer.nil?
        store.acquire_org = Merchant::AcquirerOrg.where(acquirer_code: evaluator.acquirer[:code]).first ||
            Merchant::AcquirerOrg.create!(acquirer_code: evaluator.acquirer[:code], acquirer_name: evaluator.acquirer[:name])
        store.save!
      end
    end
  end
end
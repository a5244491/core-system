require 'spec_helper'

describe Merchant::MerchantStore do
  it 'should save and destroy properly' do
    store = Merchant::MerchantStore.create! name: 'test', standard_rate: 0.01, merchant_number: '11', status: 'editing'
    store.credit_account.should be_nil
    store.create_credit_account(mobile: 'test1').should be_true
    Merchant::MerchantStore.first.payment_plans.count.should be ==0
    store.credit_account.should_not be_nil
    Member::MerchantCreditAccount.count.should be ==1
    store.destroy
    Merchant::MerchantStore.count.should be ==0
    Member::MerchantCreditAccount.count.should be ==0
  end

  it 'should save and persistence acquirer organization' do
    acquirer_org = Merchant::AcquirerOrg.create!(acquirer_name: 'cangjingkong', acquirer_code: '123')
    store = Merchant::MerchantStore.new
    store.name ='123'
    store.merchant_number = '123'
    store.acquire_org = acquirer_org
    store.save
    store.acquire_org.should_not be_nil
    store.acquire_org.id.should eq acquirer_org.id
  end
end

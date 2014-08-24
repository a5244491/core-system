require 'spec_helper'

describe Member::MerchantCreditAccount do
  before :each do
    @store = create(:merchant_store, usable_credit: 8000)
    @account = @store.credit_account
  end

  it 'should apply credit account' do
    @account.submit_credit_cashing_application!(5000)
    @account.usable_credit.should == 3000
    @account.locked_credit.should == 5000
    Member::CreditCashingApplication.count.should == 1
    application = Member::CreditCashingApplication.first
    application.bank_card.should == @store.clearance_account_num
    application.bank_name.should == @store.clearance_account_bank
    application.amount.should == 5000
    application.status.should == Member::CreditCashingApplication::PROCESSING
  end
end

require 'spec_helper'

describe Member::CreditCashingApplication do
  before :each do
    @account =create(:individual_credit_account_with_cashing_card, usable_credit: 8000)
  end

  it 'should approve credit_cashing' do
    @account.submit_credit_cashing_application!(5000)
    application = Member::CreditCashingApplication.first
    application.approve!('test')
    application.status.should == Member::CreditCashingApplication::PROCESSED
    @account = Member::IndividualCreditAccount.find(@account.id)
    @account.usable_credit.should == 3000
    @account.cashed_credit.should == 5000
    @account.locked_credit.should == 0

    transaction_log = Trade::TransactionLog.first
    transaction_log.should_not be_nil
    transaction_log.log_type.should == Trade::TransactionLog::VICE
    transaction_log.transaction_datetime.should_not be_nil
    transaction_log.transaction_type.should == Trade::TransactionLog::CREDIT_CASHING
    transaction_log.credit_delta.should == -5000
    transaction_log.user_tag.should be_nil
    transaction_log.media_num.should == @account.bank_cards.first.card_num
    transaction_log.media_type.should == Member::PaymentMedia::BANK_CARD
    transaction_log.credit_account_id.should == @account.id
    transaction_log.mobile.should == '123456'
    transaction_log.customer_name.should == 'test'
    transaction_log.matched_bank.should == 'test_bank'
    transaction_log.internal_seq_num.should == 0
    transaction_log.ref_id.length.should > 10
  end

  it 'should reject credit_cashing' do
    @account.submit_credit_cashing_application!(5000)
    application = Member::CreditCashingApplication.first
    application.reject!('test')
    application.status.should == Member::CreditCashingApplication::REJECTED
    @account = Member::IndividualCreditAccount.find(@account.id)
    @account.usable_credit.should == 8000
    @account.cashed_credit.should == 0
    @account.locked_credit.should == 0
    Trade::TransactionLog.count.should == 0
  end
end

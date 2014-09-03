require 'spec_helper'
require 'ostruct'

describe Pay::NonePaymentPlan do
  before :each do
    @payment_plan = create(:none_payment_plan)
  end

  describe 'create transaction' do
    it 'should create correct transaction' do
      transaction = @payment_plan.create_transaction(1000)
      transaction.actual_money_amount.should be == 1000
      transaction.merchant_rate.should be_nil
      transaction.save.should be_true
      Trade::Transaction.count.should be == 1
      Trade::Transaction.first.transaction_type.should be == 'none'
    end
  end

  describe 'transaction done' do
    it 'should correctly finish transaction without referer' do
      transaction = @payment_plan.create_transaction(1000, @credit_account)
      transaction.transaction_datetime = Time.now
      transaction.done
      Trade::TransactionLog.count.should be == 1
      log = Trade::TransactionLog.first
      log.log_type.should be == Trade::TransactionLog::PRIMARY
      log.transaction_type.should be == 'none'
      log.actual_money_amount.should be == 1000
    end

    it 'should not finish duplicate transaction' do
      transaction = @payment_plan.create_transaction(1000, @credit_account)
      transaction.stub(:destroy)
      transaction.save!
      transaction.finish
      expect {Trade::Transaction.first.finish}.to raise_error ActiveRecord::RecordNotUnique
    end
  end
end
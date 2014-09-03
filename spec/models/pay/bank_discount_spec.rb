require 'spec_helper'

describe Pay::BankDiscount do

  it 'should validate discount_amount' do
    expect {Pay::BankDiscount.create!(discount_type: Pay::PaymentPlan::CASH,
                                          discount_amount: -1,
                                          status: Pay::PaymentPlan::VALID)}.to raise_error ActiveRecord::RecordInvalid
  end

  it 'should validate minimal_money_amount' do
    expect {Pay::BankDiscount.create!(discount_type: Pay::PaymentPlan::CASH, discount_amount: 1000,
                                          status: Pay::PaymentPlan::VALID, minimal_money_amount: -11)}.to raise_error ActiveRecord::RecordInvalid
  end

  it 'should save for discount_type rate' do
    Pay::BankDiscount.create!(discount_type: Pay::PaymentPlan::RATE, discount_rate: 0.1,
                                  status: Pay::PaymentPlan::VALID, minimal_money_amount: 1)
    Pay::BankDiscount.count.should be ==1
  end

  it 'should save for discount_type cash' do
    Pay::BankDiscount.create!(discount_type: Pay::PaymentPlan::CASH, discount_amount: 1000,
                                  status: Pay::PaymentPlan::VALID, minimal_money_amount: 1)
    Pay::BankDiscount.count.should be ==1
  end

  describe 'cash discount' do
    before :each do
      @payment_plan = create(:bank_discount, discount_amount: 100)
    end

    it 'should create correct transaction' do
      transaction = @payment_plan.create_transaction(1000)
      transaction.actual_money_amount.should be == 900
      transaction.merchant_rate.should be == @payment_plan.merchant_rate
      transaction.save.should be_true
      Trade::Transaction.count.should be == 1
      Trade::Transaction.first.transaction_type.should be == Pay::PaymentPlan::BANK_DISCOUNT
    end
  end

  describe 'rate discount' do
    before :each do
      @payment_plan = create(:bank_discount, discount_rate: 0.15, minimal_money_amount: 100)
    end

    it 'should create correct transaction' do
      transaction = @payment_plan.create_transaction(1000)
      transaction.actual_money_amount.should be == 850
      transaction.merchant_rate.should be == @payment_plan.merchant_rate
      transaction.save.should be_true
      Trade::Transaction.count.should be == 1
      Trade::Transaction.first.transaction_type.should be == Pay::PaymentPlan::BANK_DISCOUNT
    end

    it 'should create correct transaction for rate and amount mixed rule' do
      @payment_plan.update(discount_amount: 50)
      transaction = @payment_plan.create_transaction(1000)
      transaction.actual_money_amount.should be == 800
      transaction.merchant_rate.should be == @payment_plan.merchant_rate
      transaction.save.should be_true
      Trade::Transaction.count.should be == 1
      Trade::Transaction.first.transaction_type.should be == Pay::PaymentPlan::BANK_DISCOUNT
    end
  end

  describe 'transaction done' do
    before :each do
      @payment_plan = create(:bank_discount, discount_amount: 100)
    end
    it 'should correctly finish' do
      transaction = @payment_plan.create_transaction(1000)
      transaction.transaction_datetime = Time.now
      transaction.done
      Trade::TransactionLog.count.should be == 1
      log = Trade::TransactionLog.first
      log.log_type.should be == Trade::TransactionLog::PRIMARY
      log.transaction_type.should be == Trade::TransactionLog::BANK_DISCOUNT
      log.actual_money_amount.should be == 900
    end

    it 'should not finish duplicate transaction' do
      transaction = @payment_plan.create_transaction(1000)
      transaction.stub(:destroy)
      transaction.save!
      transaction.finish
      expect {Trade::Transaction.first.finish}.to raise_error ActiveRecord::RecordNotUnique
    end
  end
end

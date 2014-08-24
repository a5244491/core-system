require 'spec_helper'

describe Pay::BankDiscount do
  it 'should validate discount_type' do
    expect {Pay::BankDiscount.create!(discount_type: 'non-exists', status: Pay::PaymentPlan::VALID)}.to raise_error ActiveRecord::RecordInvalid
  end

  it 'should validate discount_rate' do
    expect {Pay::BankDiscount.create!(discount_type: Pay::PaymentPlan::RATE,
                                          discount_rate: 1.1,
                                          status: Pay::PaymentPlan::VALID)}.to raise_error ActiveRecord::RecordInvalid
  end

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
    Pay::BankDiscount.count.should == 1
  end

  it 'should save for discount_type cash' do
    Pay::BankDiscount.create!(discount_type: Pay::PaymentPlan::CASH, discount_amount: 1000,
                                  status: Pay::PaymentPlan::VALID, minimal_money_amount: 1)
    Pay::BankDiscount.count.should == 1
  end
end

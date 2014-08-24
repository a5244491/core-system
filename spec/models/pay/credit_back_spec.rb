require 'spec_helper'

describe Pay::CreditBack do
  it 'should save invalid plan' do
    Pay::CreditBack.create!(merchant_rate: 0.1, referer_rate: 0.03, customer_rate: 0.05)
    Pay::PaymentPlan.count.should == 1
    Pay::CreditBack.first.merchant_store.should be_nil
    Pay::PaymentPlan.valid.count.should == 0
    Pay::PaymentPlan.invalid.count.should == 1
    Pay::PaymentPlan.first.is_valid?.should be_false
  end

  it 'should save valid plan' do
    Pay::CreditBack.create!(merchant_rate: 0.1, referer_rate: 0.03, customer_rate: 0.05, status: Pay::PaymentPlan::VALID)
    Pay::PaymentPlan.valid.count.should == 1
    Pay::PaymentPlan.invalid.count.should == 0
    Pay::PaymentPlan.first.is_valid?.should be_true
  end

  it 'should be invalid if valid time till has passed' do
    Pay::CreditBack.create!(merchant_rate: 0.1, referer_rate: 0.03, customer_rate: 0.05,
                                status: Pay::PaymentPlan::VALID,
                                valid_till: 1.minute.ago
    )
    Pay::PaymentPlan.valid.count.should == 0
    Pay::PaymentPlan.invalid.count.should == 1
    Pay::PaymentPlan.first.is_valid?.should be_false
  end

  it 'should be invalid if valid from till has not reached yet' do
    Pay::CreditBack.create!(merchant_rate: 0.1, referer_rate: 0.03, customer_rate: 0.05,
                                status: Pay::PaymentPlan::VALID,
                                valid_till: 10.minute.from_now,
                                valid_from: 1.minute.from_now
    )
    Pay::PaymentPlan.valid.count.should == 0
    Pay::PaymentPlan.invalid.count.should == 1
    Pay::PaymentPlan.first.is_valid?.should be_false
  end

  it 'should be valid if valid time span matches' do
    Pay::CreditBack.create!(merchant_rate: 0.1, referer_rate: 0.03, customer_rate: 0.05,
                                status: Pay::PaymentPlan::VALID,
                                valid_till: 1.minute.from_now,
                                valid_from: 1.minute.ago
    )
    Pay::PaymentPlan.valid.count.should == 1
    Pay::PaymentPlan.invalid.count.should == 0
    Pay::PaymentPlan.first.is_valid?.should be_true
  end

  it 'should update store voucher status' do
    @store = create(:merchant_store)
    @plan = Pay::CreditBack.create!(merchant_rate: 0.1, referer_rate: 0.03, customer_rate: 0.05,
                                        status: Pay::PaymentPlan::VALID,
                                        valid_till: 1.minute.from_now,
                                        valid_from: 1.minute.ago, merchant_store_id: @store.id)
    @store.reload.accept_global_voucher.should == false
    @store.reload.accept_own_voucher.should == false
    @plan.voucher_status = Pay::PaymentPlan::ACCEPT_SELF
    @plan.save!
    @store.reload.accept_global_voucher.should == false
    @store.reload.accept_own_voucher.should == true
    @plan.voucher_status = Pay::PaymentPlan::ACCEPT_GLOBAL
    @plan.save!
    @store.reload.accept_global_voucher.should == true
    @store.reload.accept_own_voucher.should == false
    @plan.voucher_status = Pay::PaymentPlan::ACCEPT_ALL
    @plan.save!
    @store.reload.accept_global_voucher.should == true
    @store.reload.accept_own_voucher.should == true

    @plan.voucher_status = Pay::PaymentPlan::ACCEPT_NONE
    @plan.save!
    @store.reload.accept_global_voucher.should == false
    @store.reload.accept_own_voucher.should == false
  end
end

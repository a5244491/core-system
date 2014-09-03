require 'spec_helper'

describe Pay::CreditBack do
  it 'should save invalid plan' do
    Pay::CreditBack.create!(merchant_rate: 0.1, referer_rate: 0.03, customer_rate: 0.05)
    Pay::PaymentPlan.count.should be ==1
    Pay::CreditBack.first.merchant_store.should be_nil
    Pay::PaymentPlan.valid.count.should be ==0
    Pay::PaymentPlan.invalid.count.should be ==1
    Pay::PaymentPlan.first.is_valid?.should be_false
  end

  it 'should save valid plan' do
    Pay::CreditBack.create!(merchant_rate: 0.1, referer_rate: 0.03, customer_rate: 0.05, status: Pay::PaymentPlan::VALID)
    Pay::PaymentPlan.valid.count.should be ==1
    Pay::PaymentPlan.invalid.count.should be ==0
    Pay::PaymentPlan.first.is_valid?.should be_true
  end

  it 'should be invalid if valid time till has passed' do
    Pay::CreditBack.create!(merchant_rate: 0.1, referer_rate: 0.03, customer_rate: 0.05,
                                status: Pay::PaymentPlan::VALID,
                                valid_till: 1.minute.ago
    )
    Pay::PaymentPlan.valid.count.should be  ==0
    Pay::PaymentPlan.invalid.count.should be  ==1
    Pay::PaymentPlan.first.is_valid?.should be_false
  end

  it 'should be invalid if valid from till has not reached yet' do
    Pay::CreditBack.create!(merchant_rate: 0.1, referer_rate: 0.03, customer_rate: 0.05,
                                status: Pay::PaymentPlan::VALID,
                                valid_till: 10.minute.from_now,
                                valid_from: 1.minute.from_now
    )
    Pay::PaymentPlan.valid.count.should be ==0
    Pay::PaymentPlan.invalid.count.should be ==1
    Pay::PaymentPlan.first.is_valid?.should be_false
  end

  it 'should be valid if valid time span matches' do
    Pay::CreditBack.create!(merchant_rate: 0.1, referer_rate: 0.03, customer_rate: 0.05,
                                status: Pay::PaymentPlan::VALID,
                                valid_till: 1.minute.from_now,
                                valid_from: 1.minute.ago
    )
    Pay::PaymentPlan.valid.count.should be ==1
    Pay::PaymentPlan.invalid.count.should be ==0
    Pay::PaymentPlan.first.is_valid?.should be_true
  end

  it 'should update store voucher status' do
    @store = create(:merchant_store)
    @plan = Pay::CreditBack.create!(merchant_rate: 0.1, referer_rate: 0.03, customer_rate: 0.05,
                                        status: Pay::PaymentPlan::VALID,
                                        valid_till: 1.minute.from_now,
                                        valid_from: 1.minute.ago, merchant_store_id: @store.id)
    @store.reload.accept_global_voucher.should be  ==false
    @store.reload.accept_own_voucher.should be ==false
    @plan.voucher_status = Pay::PaymentPlan::ACCEPT_SELF
    @plan.save!
    @store.reload.accept_global_voucher.should be ==false
    @store.reload.accept_own_voucher.should be ==true
    @plan.voucher_status = Pay::PaymentPlan::ACCEPT_GLOBAL
    @plan.save!
    @store.reload.accept_global_voucher.should be ==true
    @store.reload.accept_own_voucher.should be  ==false
    @plan.voucher_status = Pay::PaymentPlan::ACCEPT_ALL
    @plan.save!
    @store.reload.accept_global_voucher.should be  ==true
    @store.reload.accept_own_voucher.should be  ==true

    @plan.voucher_status = Pay::PaymentPlan::ACCEPT_NONE
    @plan.save!
    @store.reload.accept_global_voucher.should be ==false
    @store.reload.accept_own_voucher.should be ==false
  end

  describe 'apply consumption credit' do
    before :each do
      @credit_account = create(:individual_credit_account)
    end

    it 'should apply consumption credit' do
      @credit_account.apply_consumption_credit!(100, nil?)
      @credit_account = Member::CreditAccount.first
      @credit_account.total_credit.should be == 100
      @credit_account.usable_credit.should be == 100
      @credit_account.cashed_credit.should be == 0
      @credit_account.locked_credit.should be == 0
      @credit_account.consumption_credit.should be == 100
      @credit_account.referer_credit.should be == 0
      @credit_account.referee_credit.should be == 0

      @credit_account.apply_consumption_credit!(50, nil)
      @credit_account = Member::CreditAccount.first
      @credit_account.total_credit.should be == 150
      @credit_account.usable_credit.should be == 150
      @credit_account.cashed_credit.should be == 0
      @credit_account.locked_credit.should be == 0
      @credit_account.consumption_credit.should be == 150
      @credit_account.referer_credit.should be == 0
      @credit_account.referee_credit.should be == 0
    end
  end
  describe 'apply referer credit' do
    before :each do
      @credit_account = create(:individual_credit_account, referer_mobile: '9999888')
      @referer_account = @credit_account.referer_account
    end

    it 'should apply referer credit when there is no referer' do
      @referer_account.apply_referer_credit!(100).should be_false
      @referer_account = Member::CreditAccount.where(mobile: @credit_account.mobile).first
      @referer_account.total_credit.should be == 0
      @referer_account.usable_credit.should be == 0
      @referer_account.cashed_credit.should be == 0
      @referer_account.locked_credit.should be == 0
      @referer_account.consumption_credit.should be == 0
      @referer_account.consumption_times.should be == 0
      @referer_account.referer_credit.should be == 0
      @referer_account.referee_credit.should be == 0
    end

    it 'should apply referer credit' do
      @credit_account.apply_referer_credit!(30).should be_true
      @credit_account = Member::CreditAccount.where(mobile: @credit_account.mobile).first
      @referer_account = Member::CreditAccount.where(mobile: @referer_account.mobile).first
      @credit_account.total_credit.should be == 0
      @credit_account.usable_credit.should be == 0
      @credit_account.cashed_credit.should be == 0
      @credit_account.locked_credit.should be == 0
      @credit_account.consumption_credit.should be == 0
      @credit_account.consumption_times.should be == 0
      @credit_account.referer_credit.should be == 0
      @credit_account.referee_credit.should be == 30

      @referer_account.total_credit.should be == 30
      @referer_account.usable_credit.should be == 30
      @referer_account.cashed_credit.should be == 0
      @referer_account.locked_credit.should be == 0
      @referer_account.consumption_credit.should be == 0
      @referer_account.consumption_times.should be == 0
      @referer_account.referer_credit.should be == 30
      @referer_account.referee_credit.should be == 0
    end
  end
end
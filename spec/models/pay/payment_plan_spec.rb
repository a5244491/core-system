require 'spec_helper'

describe Pay::PaymentPlan do
  before :each do
    @store = create(:merchant_store)
  end

  describe 'determine referer rate' do
    it 'should use global configuration' do
      System::Configuration.set(System::Configuration::REFERER_RATE, '0.5')
      plan = create(:credit_back)
      plan.actual_referer_rate.should be == 0.5
    end

    it 'should override global configuration' do
      System::Configuration.set(System::Configuration::REFERER_RATE, '0.5')
      plan = create(:credit_back, referer_rate: 0.03)
      plan.actual_referer_rate.should be == plan.referer_rate
      plan = create(:credit_back, referer_rate: 0)
      plan.actual_referer_rate.should be == 0
    end
  end

  describe 'select vouchers' do
    before :each do
      @credit_account = create(:individual_credit_account)
      @store1 = create(:merchant_store, name: 'abc', merchant_number: '1234')
      @store2 = create(:merchant_store, name: 'abcd', merchant_number: '12345')
      @group1 = create(:merchant_group, stores: [@store, @store1], name: 'group1')
      @group2 = create(:merchant_group, stores: [@store, @store2], name: 'group2')
      @voucher_meta_1 = create(:active_voucher_meta, denomination: 10000, store: @store)
      @voucher_meta_2 = create(:active_voucher_meta, denomination: 5000, group: @group1)
      @voucher_meta_3 = create(:active_voucher_meta, denomination: 2000, group: @group2)
      @voucher_meta_4 = create(:active_voucher_meta, denomination: 2000)
      @voucher_meta_5 = create(:active_voucher_meta, denomination: 2000, money_condition: 1000)
      @voucher1 = @credit_account.issue_voucher(@voucher_meta_1.code)
      @voucher2 = @credit_account.issue_voucher(@voucher_meta_2.code)
      @voucher3 = @credit_account.issue_voucher(@voucher_meta_3.code)
      @voucher4 = @credit_account.issue_voucher(@voucher_meta_4.code)
      @voucher5 = @credit_account.issue_voucher(@voucher_meta_5.code)
      @payment_plan1 = create(:none_payment_plan, merchant_store: @store)
      @payment_plan2 = create(:none_payment_plan, merchant_store: @store1)
      @payment_plan3 = create(:none_payment_plan, merchant_store: @store2)
    end

    it 'should select right vouchers' do
      usable_vouchers = @payment_plan1.send(:_usable_vouchers, @credit_account, 100)
      usable_vouchers.size.should be == 4
      usable_vouchers.should include(@voucher1)
      usable_vouchers.should include(@voucher2)
      usable_vouchers.should include(@voucher3)
      usable_vouchers.should include(@voucher4)

      usable_vouchers = @payment_plan1.send(:_usable_vouchers, @credit_account, 1000)
      usable_vouchers.size.should be == 5
      usable_vouchers.should include(@voucher1)
      usable_vouchers.should include(@voucher2)
      usable_vouchers.should include(@voucher3)
      usable_vouchers.should include(@voucher4)
      usable_vouchers.should include(@voucher5)

      usable_vouchers = @payment_plan2.send(:_usable_vouchers, @credit_account, 100)
      usable_vouchers.size.should be == 2
      usable_vouchers.should include(@voucher2)
      usable_vouchers.should include(@voucher4)

      usable_vouchers = @payment_plan3.send(:_usable_vouchers, @credit_account, 100)
      usable_vouchers.size.should be == 2
      usable_vouchers.should include(@voucher3)
      usable_vouchers.should include(@voucher4)
    end
  end

  describe 'calculate voucher' do
    before :each do
      @credit_account = create(:individual_credit_account)
      @voucher_meta_100 = create(:active_voucher_meta, denomination: 10000)
      @voucher_meta_50 = create(:active_voucher_meta, denomination: 5000)
      @voucher_meta_20 = create(:active_voucher_meta, denomination: 2000)
      @credit_account.issue_voucher(@voucher_meta_20.code)
      @credit_account.issue_voucher(@voucher_meta_50.code)
      @credit_account.issue_voucher(@voucher_meta_100.code)
      @payment_plan = create(:none_payment_plan, merchant_store: @store)
    end

    it 'should use voucher with 10000 denomination when money amount is 8000' do
      transaction = @payment_plan.create_transaction(8000, @credit_account)
      transaction.actual_money_amount.should be == 1
      transaction.voucher_info.size.should be == 1
      voucher = transaction.voucher_info.first
      voucher[:voucher_id].should be == @credit_account.vouchers.where(voucher_meta: @voucher_meta_100).first.id
      voucher[:deducted_amount].should be == 7999
    end

    it 'should not user voucher if payment plan does not support voucher' do
      @payment_plan.update(voucher_status: Pay::PaymentPlan::ACCEPT_NONE)
      transaction = @payment_plan.create_transaction(8000, @credit_account)
      transaction.actual_money_amount.should be == 8000
    end

    it 'should not use voucher if money_amount = 1' do
      transaction = @payment_plan.create_transaction(1, @credit_account)
      transaction.actual_money_amount.should be == 1
      transaction.voucher_info.should be_nil
    end

    it 'should use voucher with 5000 denomination' do
      transaction = @payment_plan.create_transaction(4900, @credit_account)
      transaction.actual_money_amount.should be == 1
      transaction.voucher_info.size.should be == 1
      voucher = transaction.voucher_info.first
      voucher[:voucher_id].should be == @credit_account.vouchers.where(voucher_meta: @voucher_meta_50).first.id
      voucher[:deducted_amount].should be == 4899
    end

    it 'should use voucher with 10000 denomination when money amount is 12000' do
      transaction = @payment_plan.create_transaction(12000, @credit_account)
      transaction.actual_money_amount.should be == 2000
      transaction.voucher_info.size.should be == 1
      voucher = transaction.voucher_info.first
      voucher[:voucher_id].should be == @credit_account.vouchers.where(voucher_meta: @voucher_meta_100).first.id
      voucher[:deducted_amount].should be == 10000
    end
  end

end
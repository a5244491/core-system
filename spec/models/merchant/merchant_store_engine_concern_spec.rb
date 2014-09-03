require 'spec_helper'
require 'ostruct'

describe Merchant::MerchantStore do
  before :each do
    @store = create(:merchant_store)
  end

  describe 'select payment plan' do
    it 'should select one payment plan' do
      plan = create(:credit_back, merchant_store: @store)
      @store.send(:find_right_plan, 'credit_back', '222', nil).id.should be == plan.id
    end

    it 'should not select payment plan of invalid status' do
      create(:credit_back, :invalid, merchant_store: @store)
      expect { @store.send(:find_right_plan, 'credit_back', '222', nil) }.to raise_error Pay::NoPlanSelectedError
    end

    it 'should not select payment plan passes valid time span' do
      create(:credit_back, valid_till: 1.minute.ago, merchant_store: @store)
      expect { @store.send(:find_right_plan, 'credit_back', '222', nil) }.to raise_error Pay::NoPlanSelectedError
    end

  end
  describe 'select bank discount plan' do
    before :each do
      @card_bin1 = Bank::CardBin.create!(bank_name: 'bank1', bank_bin: '123456')
      @card_bin2 = Bank::CardBin.create!(bank_name: 'bank2', bank_bin: '12345')
      @plan1 = create(:bank_discount, bank_name: @card_bin1.bank_name, merchant_store: @store)
      @plan2 = create(:bank_discount, bank_name: @card_bin2.bank_name, merchant_store: @store)
    end

    after :each do
      @card_bin1.destroy
      @card_bin2.destroy
    end

    it 'should not select any plan for not matched card' do
      expect { @store.send(:find_right_plan, Pay::PaymentPlan::BANK_DISCOUNT, '1111', nil) }.to raise_error Pay::BankCardNotMatchError
    end

    it 'should select plan that best matches bank card' do
      @store.send(:find_right_plan, Pay::PaymentPlan::BANK_DISCOUNT, '1234567', nil).bank_name.should be == @card_bin1.bank_name
      @store.send(:find_right_plan, Pay::PaymentPlan::BANK_DISCOUNT, '123457', nil).bank_name.should be == @card_bin2.bank_name
    end

    it 'should select plan that fits all bank cards' do
      plan = create(:bank_discount, merchant_store: @store)
      @store.send(:find_right_plan, Pay::PaymentPlan::BANK_DISCOUNT, '11111111', nil).id.should be == plan.id
    end

    it 'should select plan that fits all bank cards: only one plan exists' do
      Pay::BankDiscount.destroy_all
      create(:bank_discount, merchant_store: @store)
      @store.send(:find_right_plan, Pay::PaymentPlan::BANK_DISCOUNT, '11111111', nil).should_not be_nil
    end
  end

  describe 'new transaction' do
    before :each do
      @credit_account = create(:individual_credit_account, bank_card: '1112334566')
      @payment_plan = create(:credit_back, merchant_store: @store, referer_rate: 0.03)
    end

    it 'should create transaction of credit back' do
      money_amount = 1000
      transaction = @store.new_transaction(money_amount: money_amount, media_num: @credit_account.bank_cards.first.card_num, media_type: Member::PaymentMedia::BANK_CARD, plan_type: Pay::PaymentPlan::CREDIT_BACK)
      transaction.actual_money_amount.should be == money_amount
      transaction.money_amount.should be == money_amount
      transaction.merchant_rate.should be == @payment_plan.merchant_rate
      transaction.consumer_credit.should be == (money_amount * @payment_plan.customer_rate).to_i
      transaction.referer_credit.should be == (money_amount * @payment_plan.referer_rate).to_i
      transaction.transaction_type.should be == Pay::PaymentPlan::CREDIT_BACK
      transaction.payment_plan_id.should be == @payment_plan.id
      transaction.credit_account_id.should be == @credit_account.id
      transaction.merchant_store_id.should be == @store.id
      transaction.mobile.should be == @credit_account.mobile
      transaction.customer_name.should be == @credit_account.name
      transaction.media_type.should be == Member::PaymentMedia::BANK_CARD
      transaction.media_num.should be == @credit_account.bank_cards.first.card_num
      transaction.merchant_name.should be == @store.name

      transaction.finish
      @credit_account.bank_cards.first.credit_earned.should be == (money_amount * @payment_plan.customer_rate).to_i
      @credit_account.reload
      @credit_account.total_credit.should be == (money_amount * @payment_plan.customer_rate).to_i
      @credit_account.usable_credit.should be == (money_amount * @payment_plan.customer_rate).to_i
      @credit_account.cashed_credit.should be == 0
      @credit_account.locked_credit.should be == 0
      @credit_account.consumption_credit.should be == (money_amount * @payment_plan.customer_rate).to_i
      @credit_account.consumption_times.should be == 1
      @credit_account.referer_credit.should be == 0
      @credit_account.referee_credit.should be == 0

      Trade::TransactionLog.count.should be == 1
      master_log = Trade::TransactionLog.primary_log.first
      master_log.credit_delta.should be == (money_amount * @payment_plan.customer_rate).to_i
      master_log.merchant_name.should be == @store.name
      master_log.log_type.should be == Trade::TransactionLog::PRIMARY
      master_log.transaction_type.should be == Pay::PaymentPlan::CREDIT_BACK
      master_log.credit_account_id.should be == @credit_account.id
      master_log.mobile.should be == @credit_account.mobile
      master_log.actual_money_amount.should be == money_amount
      master_log.merchant_store_id.should be == @store.id
      master_log.media_num.should be == @credit_account.bank_cards.first.card_num
      master_log.media_type.should be == Member::PaymentMedia::BANK_CARD
      master_log.money_amount.should be == money_amount
      master_log.actual_money_amount.should be == money_amount
      master_log.mobile.should be == @credit_account.mobile
      master_log.customer_name.should be == @credit_account.name

      Trade::Transaction.count.should be == 0
    end
  end
  describe 'perform marketing plan' do
    before :each do
      @credit_account = create(:individual_credit_account)
      @voucher_meta1 = create(:active_voucher_meta)
      @voucher_meta2 = create(:active_voucher_meta)
    end
    describe 'perform register rule' do
      before :each do
        @marketing_rule = create(:register_rule, :valid, merchant_store: @store)
        @post_action1 = create(:voucher_action, voucher_meta: @voucher_meta1, marketing_rule: @marketing_rule)
        @post_action2 = create(:voucher_action, voucher_meta: @voucher_meta2, marketing_rule: @marketing_rule)
      end

      it 'should perform bind card rule' do
        @store.reload.perform_marketing_rule(Merchant::MarketingRule::REGISTER, @credit_account.id)
        @credit_account.reload
        @credit_account.vouchers.size.should be == 2
        @credit_account.vouchers.exists?(voucher_meta: @voucher_meta1).should be_true
        @credit_account.vouchers.exists?(voucher_meta: @voucher_meta2).should be_true
        log1 = Trade::VoucherTransactionLog.where(voucher_meta_code: @voucher_meta1.code).first
        log1.issue_event.should be == Trade::VoucherTransactionLog::SYSTEM
        log1.merchant_num.should be == @store.merchant_number
        log1.merchant_name.should be == @store.name
        log1.merchant_store_id.should be == @store.id
        log1.primary_transaction_ref_id.should be_nil

        log1 = Trade::VoucherTransactionLog.where(voucher_meta_code: @voucher_meta2.code).first
        log1.issue_event.should be == Trade::VoucherTransactionLog::SYSTEM
        log1.merchant_num.should be == @store.merchant_number
        log1.merchant_name.should be == @store.name
        log1.merchant_store_id.should be == @store.id
        log1.primary_transaction_ref_id.should be_nil
      end

      it 'should not perform marketing rule if rule is invalid' do
        @marketing_rule.update(status: Rule::INACTIVE)
        @store.reload.perform_marketing_rule(Merchant::MarketingRule::REGISTER, @credit_account.id)
        @credit_account.vouchers.size.should be == 0
      end
    end
    describe 'perform bind card rule' do
      before :each do
        @marketing_rule = create(:bind_card_rule, :valid, merchant_store: @store)
        @post_action1 = create(:voucher_action, voucher_meta: @voucher_meta1, marketing_rule: @marketing_rule)
        @post_action2 = create(:voucher_action, voucher_meta: @voucher_meta2, marketing_rule: @marketing_rule)
      end

      it 'should perform bind card rule' do
        @store.reload.perform_marketing_rule(Merchant::MarketingRule::BIND_CARD, @credit_account.id)
        @credit_account.reload
        @credit_account.vouchers.size.should be == 2
        @credit_account.vouchers.exists?(voucher_meta: @voucher_meta1).should be_true
        @credit_account.vouchers.exists?(voucher_meta: @voucher_meta2).should be_true
        log1 = Trade::VoucherTransactionLog.where(voucher_meta_code: @voucher_meta1.code).first
        log1.issue_event.should be == Trade::VoucherTransactionLog::SYSTEM
        log1.merchant_num.should be == @store.merchant_number
        log1.merchant_name.should be == @store.name
        log1.merchant_store_id.should be == @store.id
        log1.primary_transaction_ref_id.should be_nil

        log1 = Trade::VoucherTransactionLog.where(voucher_meta_code: @voucher_meta2.code).first
        log1.issue_event.should be == Trade::VoucherTransactionLog::SYSTEM
        log1.merchant_num.should be == @store.merchant_number
        log1.merchant_name.should be == @store.name
        log1.merchant_store_id.should be == @store.id
        log1.primary_transaction_ref_id.should be_nil
      end

      it 'should not perform marketing rule is rule is invalid' do
        @marketing_rule.update(status: Rule::INACTIVE)
        @store.reload.perform_marketing_rule(Merchant::MarketingRule::BIND_CARD, @credit_account.id)
        @credit_account.vouchers.size.should be == 0
      end
    end

    describe 'perform transaction rule' do
      before :each do
        @marketing_rule1 = create(:transaction_rule, :valid, merchant_store: @store, money_condition: 1000)
        @marketing_rule2 = create(:transaction_rule, :valid, merchant_store: @store)
        @payment_plan1 = create(:none_payment_plan, marketing_rules: [@marketing_rule1])
        @payment_plan2 = create(:none_payment_plan, marketing_rules: [@marketing_rule1, @marketing_rule2])
        @post_action1 = create(:voucher_action, voucher_meta: @voucher_meta1, marketing_rule: @marketing_rule1)
        @post_action2 = create(:voucher_action, voucher_meta: @voucher_meta2, marketing_rule: @marketing_rule2)
      end

      it 'should perform transaction rule if precondition matches' do
        master_log = create(:transaction_log, ref_id: '1234', actual_money_amount: 2000, payment_plan_id: @payment_plan1.id)
        @store.perform_marketing_rule(Merchant::MarketingRule::TRANSACTION, @credit_account, master_log.ref_id)
        @credit_account.vouchers.size.should be == 1
        @credit_account.vouchers.exists?(voucher_meta: @voucher_meta1).should be_true
        log1 = Trade::VoucherTransactionLog.first
        log1.issue_event.should be == Trade::VoucherTransactionLog::CONSUMPTION
        log1.merchant_num.should be == @store.merchant_number
        log1.merchant_name.should be == @store.name
        log1.merchant_store_id.should be == @store.id
        log1.primary_transaction_ref_id.should be == master_log.ref_id
      end

      it 'should not perform transaction rule if precondition does not match' do
        master_log = create(:transaction_log, ref_id: '1234', actual_money_amount: 200, payment_plan_id: @payment_plan1.id)
        @store.perform_marketing_rule(Merchant::MarketingRule::TRANSACTION, @credit_account, master_log.ref_id)
        @credit_account.vouchers.size.should be == 0
        Trade::VoucherTransactionLog.count.should be == 0
      end

      it 'should not perform transaction rule if marketing rule is invalid' do
        @marketing_rule1.update(status: Rule::INACTIVE)
        master_log = create(:transaction_log, ref_id: '1234', actual_money_amount: 2000, payment_plan_id: @payment_plan1.id)
        @store.perform_marketing_rule(Merchant::MarketingRule::TRANSACTION, @credit_account, master_log.ref_id)
        @credit_account.vouchers.size.should be == 0
        Trade::VoucherTransactionLog.count.should be == 0
      end

      it 'should perform all rules that matches' do
        master_log = create(:transaction_log, ref_id: '1234', actual_money_amount: 2000, payment_plan_id: @payment_plan2.id)
        @store.perform_marketing_rule(Merchant::MarketingRule::TRANSACTION, @credit_account, master_log.ref_id)
        @credit_account.vouchers.size.should be == 2
        @credit_account.vouchers.exists?(voucher_meta: @voucher_meta1).should be_true
        @credit_account.vouchers.exists?(voucher_meta: @voucher_meta2).should be_true
        log1 = Trade::VoucherTransactionLog.where(voucher_meta_code: @voucher_meta1.code).first
        log1.issue_event.should be == Trade::VoucherTransactionLog::CONSUMPTION
        log1.merchant_num.should be == @store.merchant_number
        log1.merchant_name.should be == @store.name
        log1.merchant_store_id.should be == @store.id
        log1.primary_transaction_ref_id.should be == master_log.ref_id

        log1 = Trade::VoucherTransactionLog.where(voucher_meta_code: @voucher_meta2.code).first
        log1.issue_event.should be == Trade::VoucherTransactionLog::CONSUMPTION
        log1.merchant_num.should be == @store.merchant_number
        log1.merchant_name.should be == @store.name
        log1.merchant_store_id.should be == @store.id
        log1.primary_transaction_ref_id.should be == master_log.ref_id
      end
    end
  end
end
require 'spec_helper'

describe Merchant::VoucherAction do
  before :each do
    @voucher_meta = create(:active_voucher_meta)
    @post_action = create(:voucher_action, voucher_meta: @voucher_meta)
    @credit_account = create(:individual_credit_account)
    @store = create(:merchant_store)
    @master_log = Trade::TransactionLog.new(ref_id: '111', transaction_datetime: Time.now)
  end

  describe 'triggered by bind card' do
    it 'should perform action when store and master log is specified' do
      @post_action.perform_action(credit_account: @credit_account, trigger_event: Merchant::MarketingRule::BIND_CARD,
                                  merchant_store: @store, master_log: @master_log)
      @credit_account.vouchers.size.should be == 1
      @credit_account.vouchers.exists?(voucher_meta: @voucher_meta).should be_true
      log = Trade::VoucherTransactionLog.where(voucher_meta_code: @voucher_meta.code).first
      log.issue_event.should be == Trade::VoucherTransactionLog::SYSTEM
      log.merchant_num.should be == @store.merchant_number
      log.merchant_name.should be == @store.name
      log.merchant_store_id.should be == @store.id
      log.primary_transaction_ref_id.should be == @master_log.ref_id
      log.transaction_datetime.utc.to_i.should be == @master_log.transaction_datetime.utc.to_i
    end
  end
  describe 'triggered by register' do
    it 'should perform action when store and master log is not specified' do
      @post_action.perform_action(credit_account: @credit_account, trigger_event: Merchant::MarketingRule::REGISTER)
      @credit_account.vouchers.size.should be == 1
      @credit_account.vouchers.exists?(voucher_meta: @voucher_meta).should be_true
      log = Trade::VoucherTransactionLog.where(voucher_meta_code: @voucher_meta.code).first
      log.issue_event.should be == Trade::VoucherTransactionLog::SYSTEM
      log.merchant_num.should be_nil
      log.merchant_name.should be_nil
      log.merchant_store_id.should be_nil
      log.primary_transaction_ref_id.should be_nil
    end

    it 'should perform action when store and master log is specified' do
      @post_action.perform_action(credit_account: @credit_account, trigger_event: Merchant::MarketingRule::REGISTER,
                                  merchant_store: @store, master_log: @master_log)
      @credit_account.vouchers.size.should be == 1
      @credit_account.vouchers.exists?(voucher_meta: @voucher_meta).should be_true
      log = Trade::VoucherTransactionLog.where(voucher_meta_code: @voucher_meta.code).first
      log.issue_event.should be == Trade::VoucherTransactionLog::SYSTEM
      log.merchant_num.should be == @store.merchant_number
      log.merchant_name.should be == @store.name
      log.merchant_store_id.should be == @store.id
      log.primary_transaction_ref_id.should be == @master_log.ref_id
      log.transaction_datetime.utc.to_i.should be == @master_log.transaction_datetime.utc.to_i
    end
  end

  describe 'triggered by transaction' do
    it 'should perform action when store and master log is specified' do
      @post_action.perform_action(credit_account: @credit_account, trigger_event: Merchant::MarketingRule::TRANSACTION,
                                  merchant_store: @store, master_log: @master_log)
      @credit_account.vouchers.size.should be == 1
      @credit_account.vouchers.exists?(voucher_meta: @voucher_meta).should be_true
      log = Trade::VoucherTransactionLog.where(voucher_meta_code: @voucher_meta.code).first
      log.issue_event.should be == Trade::VoucherTransactionLog::CONSUMPTION
      log.merchant_num.should be == @store.merchant_number
      log.merchant_name.should be == @store.name
      log.merchant_store_id.should be == @store.id
      log.primary_transaction_ref_id.should be == @master_log.ref_id
      log.transaction_datetime.utc.to_i.should be == @master_log.transaction_datetime.utc.to_i
    end

    it 'should issue more than one voucher' do
      @post_action.voucher_count = 2
      @post_action.save!
      @post_action.perform_action(credit_account: @credit_account, trigger_event: Merchant::MarketingRule::TRANSACTION,
                                  merchant_store: @store, master_log: @master_log)
      @credit_account.vouchers.size.should be == 2
      Trade::VoucherTransactionLog.count.should be == 2
    end
  end

end
#encoding:utf-8
require 'spec_helper'

describe Engine::POS::TransactionsAPI do
  before :each do
    @store = create(:merchant_store, :active)
    @credit_account = create(:individual_credit_account, mobile: '13981842941', name: 'testxx', bank_card: '5324211111111111111111')
    @bank_card = @credit_account.bank_cards.first
    create(:card_bin, bank_name: '中国建设银行', bank_bin: '5324')
    create(:card_bin, bank_name: '中国工商银行', bank_bin: '5442')
  end

  describe 'cash discount' do
    before :each do
      @payment_plan_icbc = create(:bank_discount, bank_name: '中国工商银行', merchant_store: @store, discount_amount: 1000)
      @payment_plan_ccb = create(:bank_discount, bank_name: '中国建设银行', merchant_store: @store, discount_amount: 500)
      @payment_plan_all = create(:bank_discount, merchant_store: @store, discount_amount: 400, minimal_money_amount: 400)
    end

    it 'should apply payment plan ccb for member card' do
      SmsWorker.should_not_receive(:perform_async)
      post '/engine/pos/transactions', {bank_card: @bank_card.card_num, merchant_num: @store.merchant_number, money_amount: 1500, plan_type: 'bank_discount'}.merge(platform_account_key_secret)
      response.status.should be == 200
      body = JSON.parse(response.body)
      body['actual_money_amount'].should be == 1000
      body['trans_id'].should_not be_nil
      body['plan_id'].should be == @payment_plan_ccb.id
      body['merchant_rate'].to_f.should be == @payment_plan_ccb.merchant_rate
      body['receipt']['transaction_type'].should be == Pay::BankDiscount.new.plan_name
      body['receipt']['footer_m'].should_not be_nil
      body['receipt']['extra_rows_m'].should_not be_nil
      body['receipt']['extra_rows'].should_not be_nil
      body['receipt']['footer_m'].should_not be_nil
      put "/engine/pos/transactions/#{body['trans_id']}", {status: 1,
                                                    transaction_datetime: '2013-07-18 15:47:35',
                                                    sequence_num: '111',
                                                    terminal_num: '222',
                                                    merchant_amount: 970
      }.merge(platform_account_key_secret)
      response.status.should be == 200
      Trade::TransactionLog.count.should be == 1
      master_log = Trade::TransactionLog.primary_log.first
      master_log.merchant_rate = @payment_plan_ccb.merchant_rate
      master_log.credit_delta.should be == 0
      master_log.merchant_name.should be == @store.name
      master_log.transaction_datetime.localtime.strftime('%Y-%m-%d %H:%M:%S').should be =='2013-07-18 15:47:35'
      master_log.log_type.should be == Trade::TransactionLog::PRIMARY
      master_log.transaction_type.should be == Trade::TransactionLog::BANK_DISCOUNT
      master_log.credit_account_id.should be == @credit_account.id
      master_log.sequence_number.should be == '111'
      master_log.terminal_num.should be =='222'
      master_log.merchant_store_id.should be == @store.id
      master_log.media_num.should be == @bank_card.card_num
      master_log.media_type.should be == Member::PaymentMedia::BANK_CARD
      master_log.money_amount.should be == 1500
      master_log.actual_money_amount.should be == 1000
      master_log.mobile.should be == @credit_account.mobile
      master_log.customer_name.should be == @credit_account.name
      master_log.merchant_amount.should be == 970
      master_log.merchant_num.should be == @store.merchant_number
      master_log.plan_type.should be == Pay::PaymentPlan::BANK_DISCOUNT
      master_log.matched_bank.should be == '中国建设银行'
      Trade::Transaction.count.should be == 0
      Member::CreditAccount.find(@credit_account.id).consumption_times.should be == 1
    end

    it 'should apply payment plan icbc for none member card' do
      post '/engine/pos/transactions', {bank_card: '544210111111111', merchant_num: @store.merchant_number, money_amount: 1500, plan_type: 'bank_discount'}.merge(platform_account_key_secret)
      response.status.should be == 200
      body = JSON.parse(response.body)
      body['actual_money_amount'].should be == 500
      body['merchant_rate'].to_f.should be == @payment_plan_icbc.merchant_rate
      body['trans_id'].should_not be_nil
      body['plan_id'].should be == @payment_plan_icbc.id
      body['receipt']['transaction_type'].should be == Pay::BankDiscount.new.plan_name
      body['receipt']['footer_m'].should_not be_nil
      body['receipt']['extra_rows_m'].should_not be_nil
      body['receipt']['extra_rows'].should_not be_nil
      body['receipt']['footer_m'].should_not be_nil
      put "/engine/pos/transactions/#{body['trans_id']}", {status: 1,
                                                    transaction_datetime: '2013-07-18 15:47:35',
                                                    sequence_num: '111',
                                                    terminal_num: '222',
                                                    merchant_amount: 485
      }.merge(platform_account_key_secret)
      response.status.should be == 200
      Trade::TransactionLog.count.should be == 1
      master_log = Trade::TransactionLog.primary_log.first
      master_log.credit_delta.should be == 0
      master_log.merchant_rate = @payment_plan_ccb.merchant_rate
      master_log.merchant_name.should be == @store.name
      master_log.transaction_datetime.to_s.should_not be_nil
      master_log.log_type.should be == Trade::TransactionLog::PRIMARY
      master_log.transaction_type.should be == Trade::TransactionLog::BANK_DISCOUNT
      master_log.credit_account_id.should be == nil
      master_log.sequence_number.should be == '111'
      master_log.terminal_num.should be =='222'
      master_log.merchant_store_id.should be == @store.id
      master_log.media_num.should be == '544210111111111'
      master_log.media_type.should be == Member::PaymentMedia::BANK_CARD
      master_log.money_amount.should be == 1500
      master_log.actual_money_amount.should be == 500
      master_log.mobile.should be == nil
      master_log.customer_name.should be == nil
      master_log.merchant_amount.should be == 485
      master_log.merchant_num.should be == @store.merchant_number
      master_log.plan_type.should be == Pay::PaymentPlan::BANK_DISCOUNT
      master_log.matched_bank.should be == '中国工商银行'
      master_log.merchant_tag.should be_nil
      master_log.user_tag.should be_nil

      Trade::Transaction.count.should be == 0
    end

    it 'should apply payment plan all for non-member card' do
      post '/engine/pos/transactions', {bank_card: '111111', merchant_num: @store.merchant_number, money_amount: 1500, plan_type: 'bank_discount'}.merge(platform_account_key_secret)
      response.status.should be == 200
      body = JSON.parse(response.body)
      body['actual_money_amount'].should be == 1100
      body['trans_id'].should_not be_nil
      body['plan_id'].should be == @payment_plan_all.id
      body['merchant_rate'].to_f.should be == @payment_plan_all.merchant_rate
      body['receipt']['transaction_type'].should be == Pay::BankDiscount.new.plan_name
      body['receipt']['footer_m'].should_not be_nil
      body['receipt']['extra_rows_m'].should_not be_nil
      body['receipt']['extra_rows'].should_not be_nil
      body['receipt']['footer_m'].should_not be_nil
      put "/engine/pos/transactions/#{body['trans_id']}", {status: 1,
                                                    transaction_datetime: '2013-07-18 15:47:35',
                                                    sequence_num: '111',
                                                    terminal_num: '222',
                                                    merchant_amount: 997
      }.merge(platform_account_key_secret)
      response.status.should be == 200
      Trade::TransactionLog.count.should be == 1
      master_log = Trade::TransactionLog.primary_log.first
      master_log.credit_delta.should be == 0
      master_log.merchant_rate = @payment_plan_all.merchant_rate
      master_log.merchant_name.should be == @store.name
      master_log.transaction_datetime.localtime.strftime('%Y-%m-%d %H:%M:%S').should be =='2013-07-18 15:47:35'
      master_log.log_type.should be == Trade::TransactionLog::PRIMARY
      master_log.transaction_type.should be == Trade::TransactionLog::BANK_DISCOUNT
      master_log.credit_account_id.should be == nil
      master_log.sequence_number.should be == '111'
      master_log.terminal_num.should be =='222'
      master_log.merchant_store_id.should be == @store.id
      master_log.media_num.should be == '111111'
      master_log.media_type.should be == Member::PaymentMedia::BANK_CARD
      master_log.money_amount.should be == 1500
      master_log.actual_money_amount.should be == 1100
      master_log.mobile.should be == nil
      master_log.customer_name.should be == nil
      master_log.merchant_amount.should be == 997
      master_log.merchant_num.should be == @store.merchant_number
      master_log.plan_type.should be == Pay::PaymentPlan::BANK_DISCOUNT
      master_log.matched_bank.should be_nil
      master_log.referer_id.should be_nil
      master_log.referer_external_id.should be_nil
      master_log.referer_mobile.should be_nil
      Trade::Transaction.count.should be == 0
    end

    it 'should create correct transaction if money_amount < discount_amount' do
      @payment_plan_all.update_attribute(:minimal_money_amount, 0)
      post '/engine/pos/transactions', {bank_card: '111111', merchant_num: @store.merchant_number, money_amount: 300, plan_type: 'bank_discount'}.merge(platform_account_key_secret)
      response.status.should be == 200
      body = JSON.parse(response.body)
      body['actual_money_amount'].should be == 1
      body['trans_id'].should_not be_nil
      put "/engine/pos/transactions/#{body['trans_id']}", {status: 1,
                                                    transaction_datetime: '2013-07-18 15:47:35',
                                                    sequence_num: '111',
                                                    terminal_num: '222',
                                                    merchant_amount: 997
      }.merge(platform_account_key_secret)
      response.status.should be == 200
      Trade::TransactionLog.count.should be == 1
      master_log = Trade::TransactionLog.primary_log.first
      master_log.money_amount.should be == 300
      master_log.actual_money_amount.should be == 1
      Trade::Transaction.count.should be == 0
    end

    it 'should not create transaction for non matched card' do
      @payment_plan_all.destroy
      post '/engine/pos/transactions', {bank_card: '111111', merchant_num: @store.merchant_number, money_amount: 1500, plan_type: 'bank_discount'}.merge(platform_account_key_secret)
      response.status.should be == 419
      body = JSON.parse(response.body)
      body['screen_msg'].should be == Pay::PaymentPlanError::BANK_CARD_NOT_MATCH
    end

    it 'should not create transaction if minimal money account does not match' do
      post '/engine/pos/transactions', {bank_card: '111111', merchant_num: @store.merchant_number, money_amount: 100, plan_type: 'bank_discount'}.merge(platform_account_key_secret)
      response.status.should be == 419
      body = JSON.parse(response.body)
      body['screen_msg'].should be == '金额满4.0元才能享受此优惠'
    end

  end

  describe 'rate discount' do
    before :each do
      @payment_plan_all = create(:bank_discount, discount_rate: 0.1, minimal_money_amount: 400, merchant_store: @store)
    end

    it 'should not create transaction if minimal money account does not match' do
      post '/engine/pos/transactions', {bank_card: '111111', merchant_num: @store.merchant_number, money_amount: 100, plan_type: 'bank_discount'}.merge(platform_account_key_secret)
      response.status.should be == 419
      body = JSON.parse(response.body)
      body['screen_msg'].should be == '金额满4.0元才能享受此优惠'
    end

    it 'should apply payment plan all for none member card' do
      post '/engine/pos/transactions', {bank_card: '111111', merchant_num: @store.merchant_number, money_amount: 1000, plan_type: 'bank_discount'}.merge(platform_account_key_secret)
      response.status.should be == 200
      body = JSON.parse(response.body)
      body['actual_money_amount'].should be == 900
      body['trans_id'].should_not be_nil
      body['plan_id'].should be == @payment_plan_all.id
      body['merchant_rate'].to_f.should be == 0.03
      body['receipt']['transaction_type'].should be == Pay::BankDiscount.new.plan_name
      body['receipt']['footer_m'].should_not be_nil
      body['receipt']['extra_rows_m'].should_not be_nil
      body['receipt']['extra_rows'].should_not be_nil
      body['receipt']['footer_m'].should_not be_nil
      put "/engine/pos/transactions/#{body['trans_id']}", {status: 1,
                                                    transaction_datetime: '2013-07-18 15:47:35',
                                                    sequence_num: '111',
                                                    terminal_num: '222',
                                                    merchant_amount: 997
      }.merge(platform_account_key_secret)
      response.status.should be == 200
      Trade::TransactionLog.count.should be == 1
      master_log = Trade::TransactionLog.primary_log.first
      master_log.credit_delta.should be == 0
      master_log.merchant_rate = @payment_plan_all.merchant_rate
      master_log.merchant_name.should be == @store.name
      master_log.transaction_datetime.localtime.strftime('%Y-%m-%d %H:%M:%S').should be =='2013-07-18 15:47:35'
      master_log.log_type.should be == Trade::TransactionLog::PRIMARY
      master_log.transaction_type.should be == Trade::TransactionLog::BANK_DISCOUNT
      master_log.credit_account_id.should be == nil
      master_log.sequence_number.should be == '111'
      master_log.terminal_num.should be =='222'
      master_log.merchant_store_id.should be == @store.id
      master_log.media_num.should be == '111111'
      master_log.media_type.should be == Member::PaymentMedia::BANK_CARD
      master_log.money_amount.should be == 1000
      master_log.actual_money_amount.should be == 900
      master_log.mobile.should be == nil
      master_log.customer_name.should be == nil
      master_log.merchant_amount.should be == 997
      master_log.merchant_num.should be == @store.merchant_number
      master_log.plan_type.should be == Pay::PaymentPlan::BANK_DISCOUNT
      master_log.matched_bank.should be_nil
      Trade::Transaction.count.should be == 0
    end
  end

  describe 'with referer' do
    before :each do
      @payment_plan_all = create(:bank_discount, discount_rate: 0.1, minimal_money_amount: 400, merchant_store: @store, referer_rate: 0.03)
      @credit_account = create(:individual_credit_account, mobile: '13981842222', name: 'testxx', bank_card: '5324211111111111111133', referer_mobile: '13981842942')
      @bank_card = @credit_account.bank_cards.first
      @referer_account = @credit_account.referer_account
      @referer_account.referer_account = @store.credit_account
      @referer_account.save!
    end

    it 'should apply referer credit' do
      post '/engine/pos/transactions', {bank_card: @bank_card.card_num, merchant_num: @store.merchant_number, money_amount: 1000, plan_type: 'bank_discount'}.merge(platform_account_key_secret)
      response.status.should be == 200
      body = JSON.parse(response.body)
      body['actual_money_amount'].should be == 900
      body['trans_id'].should_not be_nil
      body['plan_id'].should be == @payment_plan_all.id
      body['merchant_rate'].to_f.should be == @payment_plan_all.merchant_rate
      body['receipt']['transaction_type'].should be == Pay::BankDiscount.new.plan_name
      body['receipt']['footer_m'].should_not be_nil
      body['receipt']['extra_rows_m'].should_not be_nil
      body['receipt']['extra_rows'].should_not be_nil
      body['receipt']['footer_m'].should_not be_nil
      put "/engine/pos/transactions/#{body['trans_id']}", {status: 1,
                                                    transaction_datetime: '2013-07-18 15:47:35',
                                                    sequence_num: '111',
                                                    terminal_num: '222',
                                                    merchant_amount: 997
      }.merge(platform_account_key_secret)
      response.status.should be == 200
      Trade::TransactionLog.count.should be == 2
      master_log = Trade::TransactionLog.primary_log.first
      master_log.credit_delta.should be == 0
      master_log.merchant_name.should be == @store.name
      master_log.merchant_rate = @payment_plan_all.merchant_rate
      master_log.transaction_datetime.localtime.strftime('%Y-%m-%d %H:%M:%S').should be =='2013-07-18 15:47:35'
      master_log.log_type.should be == Trade::TransactionLog::PRIMARY
      master_log.transaction_type.should be == Trade::TransactionLog::BANK_DISCOUNT
      master_log.credit_account_id.should be == @credit_account.id
      master_log.sequence_number.should be == '111'
      master_log.terminal_num.should be =='222'
      master_log.merchant_store_id.should be == @store.id
      master_log.media_num.should be == @bank_card.card_num
      master_log.media_type.should be == Member::PaymentMedia::BANK_CARD
      master_log.money_amount.should be == 1000
      master_log.actual_money_amount.should be == 900
      master_log.mobile.should be == @credit_account.mobile
      master_log.customer_name.should be == @credit_account.name
      master_log.merchant_amount.should be == 997
      master_log.merchant_num.should be == @store.merchant_number
      master_log.plan_type.should be == Pay::PaymentPlan::BANK_DISCOUNT
      master_log.matched_bank.should be == '中国建设银行'
      master_log.referer_id.should be == @credit_account.referer_account.id
      master_log.referer_external_id.should be == @credit_account.referer_account.external_id
      master_log.referer_mobile.should be == @credit_account.referer_account.mobile
      Trade::Transaction.count.should be == 0

      @credit_account = Member::CreditAccount.find(@credit_account.id)
      @referer_account = Member::CreditAccount.find(@referer_account.id)
      @credit_account.total_credit.should be == 0
      @credit_account.consumption_times.should be == 1
      @referer_account.total_credit.should be == 27
      @referer_account.consumption_times.should be == 0
      vice_log = Trade::TransactionLog.vice_log.first
      vice_log.credit_delta.should be == 27
      vice_log.merchant_name.should be == @store.name
      vice_log.transaction_datetime.localtime.strftime('%Y-%m-%d %H:%M:%S').should be =='2013-07-18 15:47:35'
      vice_log.log_type.should be == Trade::TransactionLog::VICE
      vice_log.transaction_type.should be == 'referer_credit'
      vice_log.credit_account_id.should be == @referer_account.id
      vice_log.sequence_number.should be == '111'
      vice_log.terminal_num.should be =='222'
      vice_log.merchant_store_id.should be == @store.id
      vice_log.media_num.should be == @bank_card.card_num
      vice_log.media_type.should be == Member::PaymentMedia::BANK_CARD
      vice_log.money_amount.should be == 0
      vice_log.actual_money_amount.should be == 0
      vice_log.mobile.should be == @referer_account.mobile
      vice_log.customer_name.should be == @referer_account.name
      vice_log.merchant_amount.should be == 0
      vice_log.merchant_num.should be == @store.merchant_number
      vice_log.plan_type.should be == Pay::PaymentPlan::BANK_DISCOUNT
      vice_log.matched_bank.should be == '中国建设银行'
      vice_log.referer_id.should be ==@referer_account.referer_account.id
      vice_log.referer_external_id.should be == @referer_account.referer_account.external_id
      vice_log.referer_mobile.should be == @referer_account.referer_account.mobile
    end

    it 'should not apply referer credit if referer rate is 0' do
      System::Configuration.set(System::Configuration::REFERER_RATE, 0)
      @payment_plan_all.referer_rate = nil
      @payment_plan_all.save!
      post '/engine/pos/transactions', {bank_card: @bank_card.card_num, merchant_num: @store.merchant_number, money_amount: 1000, plan_type: 'bank_discount'}.merge(platform_account_key_secret)
      response.status.should be == 200
      body = JSON.parse(response.body)
      body['actual_money_amount'].should be == 900
      body['trans_id'].should_not be_nil
      body['plan_id'].should be == @payment_plan_all.id
      body['merchant_rate'].to_f.should be == @payment_plan_all.merchant_rate
      body['receipt']['transaction_type'].should be == Pay::BankDiscount.new.plan_name
      body['receipt']['footer_m'].should_not be_nil
      body['receipt']['extra_rows_m'].should_not be_nil
      body['receipt']['extra_rows'].should_not be_nil
      body['receipt']['footer_m'].should_not be_nil
      put "/engine/pos/transactions/#{body['trans_id']}", {status: 1,
                                                    transaction_datetime: '2013-07-18 15:47:35',
                                                    sequence_num: '111',
                                                    terminal_num: '222',
                                                    merchant_amount: 997
      }.merge(platform_account_key_secret)
      response.status.should be == 200
      Trade::TransactionLog.count.should be == 1
      master_log = Trade::TransactionLog.primary_log.first
      master_log.credit_delta.should be == 0
      master_log.merchant_name.should be == @store.name
      master_log.merchant_rate = @payment_plan_all.merchant_rate
      master_log.transaction_datetime.localtime.strftime('%Y-%m-%d %H:%M:%S').should be =='2013-07-18 15:47:35'
      master_log.log_type.should be == Trade::TransactionLog::PRIMARY
      master_log.transaction_type.should be == Trade::TransactionLog::BANK_DISCOUNT
      master_log.credit_account_id.should be == @credit_account.id
      master_log.sequence_number.should be == '111'
      master_log.terminal_num.should be =='222'
      master_log.merchant_store_id.should be == @store.id
      master_log.media_num.should be == @bank_card.card_num
      master_log.media_type.should be == Member::PaymentMedia::BANK_CARD
      master_log.money_amount.should be == 1000
      master_log.actual_money_amount.should be == 900
      master_log.mobile.should be == @credit_account.mobile
      master_log.customer_name.should be == @credit_account.name
      master_log.merchant_amount.should be == 997
      master_log.merchant_num.should be == @store.merchant_number
      master_log.plan_type.should be == Pay::PaymentPlan::BANK_DISCOUNT
      master_log.matched_bank.should be == '中国建设银行'
      Trade::Transaction.count.should be == 0

      @credit_account = Member::CreditAccount.find(@credit_account.id)
      @referer_account = Member::CreditAccount.find(@referer_account.id)
      @credit_account.total_credit.should be == 0
      @credit_account.consumption_times.should be == 1
      @referer_account.total_credit.should be == 0
      @referer_account.consumption_times.should be == 0
    end

    it 'should revert transaction' do
      post '/engine/pos/transactions', {bank_card: @bank_card.card_num, merchant_num: @store.merchant_number, money_amount: 1000, plan_type: 'bank_discount'}.merge(platform_account_key_secret)
      response.status.should be == 200
      body = JSON.parse(response.body)
      now = Time.now.localtime.strftime('%Y-%m-%d %H:%M:%S')
      put "/engine/pos/transactions/#{body['trans_id']}", {status: 1,
                                                    transaction_datetime: now,
                                                    sequence_num: '111',
                                                    terminal_num: '222',
                                                    merchant_amount: 997
      }.merge(platform_account_key_secret)
      response.status.should be == 200
      delete "/engine/pos/transactions/#{body['trans_id']}", {reason: 'test'}.merge(platform_account_key_secret)
      response.status.should be == 200
      Trade::TransactionLog.count.should be == 4
      reverted_master_log = Trade::TransactionLog.where(status: Trade::TransactionLog::REVERTED).primary_log.first
      reverted_master_log.should_not be_nil
      reverted_master_log.actual_money_amount.should be == -900
      reverted_master_log.merchant_amount.should be == -997
      reverted_vice_log = Trade::TransactionLog.where(status: Trade::TransactionLog::REVERTED).vice_log.first
      reverted_vice_log.should_not be_nil
      reverted_vice_log.credit_delta.should be == -27
    end
  end
  describe 'revert transaction' do
    before :each do
      @payment_plan_all = create(:bank_discount, discount_rate: 0.1, minimal_money_amount: 400, merchant_store: @store, referer_rate: 0.03)
    end

    it 'should not revert non-exists transaction' do
      delete '/engine/pos/transactions/not-existing', {reason: 'test'}.merge(platform_account_key_secret)
      response.status.should be == 200
      Trade::TransactionLog.count.should be == 0
    end

    it 'should revert transaction' do
      post '/engine/pos/transactions', {bank_card: '111111', merchant_num: @store.merchant_number, money_amount: 1000, plan_type: 'bank_discount'}.merge(platform_account_key_secret)
      response.status.should be == 200
      body = JSON.parse(response.body)
      trans_id = body['trans_id']
      now = Time.now.localtime.strftime('%Y-%m-%d %H:%M:%S')
      put "/engine/pos/transactions/#{trans_id}", {status: 1,
                                            transaction_datetime: now,
                                            sequence_num: '111',
                                            terminal_num: '222',
                                            merchant_amount: 997
      }.merge(platform_account_key_secret)
      response.status.should be == 200
      delete "/engine/pos/transactions/#{trans_id}", {reason: 'test'}.merge(platform_account_key_secret)
      response.status.should be == 200
      Trade::TransactionLog.count.should be == 2
      reverted_log = Trade::TransactionLog.where(status: Trade::TransactionLog::REVERTED).first
      reverted_log.should_not be_nil
      reverted_log.actual_money_amount.should be == -900
      reverted_log.merchant_amount.should be == -997

      delete "/engine/pos/transactions/#{trans_id}", {reason: 'test'}.merge(platform_account_key_secret)
      response.status.should be == 200
      Trade::TransactionLog.count.should be == 2
    end
  end

  describe 'with voucher' do
    before :each do
      @payment_plan_all = create(:bank_discount, discount_rate: 0.1, minimal_money_amount: 400, merchant_store: @store, referer_rate: 0.03)
      @voucher_meta = create(:active_voucher_meta, denomination: 10000)
      @credit_account.issue_voucher(@voucher_meta.code)
    end
    it 'should use voucher' do
      SmsWorker.should_receive(:perform_async).with(@credit_account.mobile, anything)
      post '/engine/pos/transactions', {bank_card: @bank_card.card_num, merchant_num: @store.merchant_number, money_amount: 15000, plan_type: 'bank_discount'}.merge(platform_account_key_secret)
      response.status.should be == 200
      body = JSON.parse(response.body)
      body['actual_money_amount'].should be == 3500
      body['trans_id'].should_not be_nil
      put "/engine/pos/transactions/#{body['trans_id']}", {status: 1,
                                                    transaction_datetime: '2013-07-18 15:47:35',
                                                    sequence_num: '111',
                                                    terminal_num: '222',
                                                    merchant_amount: 997
      }.merge(platform_account_key_secret)
      response.status.should be == 200
      Trade::TransactionLog.count.should be == 1
      master_log = Trade::TransactionLog.primary_log.first
      master_log.credit_delta.should be == 0
      master_log.merchant_rate = @payment_plan_all.merchant_rate
      master_log.merchant_name.should be == @store.name
      master_log.transaction_datetime.localtime.strftime('%Y-%m-%d %H:%M:%S').should be =='2013-07-18 15:47:35'
      master_log.log_type.should be == Trade::TransactionLog::PRIMARY
      master_log.transaction_type.should be == Trade::TransactionLog::BANK_DISCOUNT
      master_log.credit_account_id.should be == @credit_account.id
      master_log.sequence_number.should be == '111'
      master_log.terminal_num.should be =='222'
      master_log.merchant_store_id.should be == @store.id
      master_log.media_num.should be == @bank_card.card_num
      master_log.media_type.should be == Member::PaymentMedia::BANK_CARD
      master_log.money_amount.should be == 15000
      master_log.actual_money_amount.should be == 3500
      master_log.mobile.should be == @credit_account.mobile
      master_log.customer_name.should be == @credit_account.name
      master_log.merchant_amount.should be == 997
      master_log.merchant_num.should be == @store.merchant_number
      master_log.plan_type.should be == Pay::PaymentPlan::BANK_DISCOUNT
      master_log.voucher_used_count.should be == 1
      master_log.voucher_deducted_amount.should be == 10000
      master_log.matched_bank.should be == '中国建设银行'
      Trade::Transaction.count.should be == 0

      @credit_account.vouchers.size.should be ==1
      voucher = @credit_account.vouchers.first
      voucher.status.should be == Member::Voucher::USED
      voucher.used_datetime.localtime.strftime('%Y-%m-%d %H:%M:%S').should be =='2013-07-18 15:47:35'
      Trade::VoucherTransactionLog.where(transaction_type: Trade::VoucherTransactionLog::USE).count.should be == 1
      voucher_log = Trade::VoucherTransactionLog.where(transaction_type: Trade::VoucherTransactionLog::USE).first
      voucher_log.transaction_datetime.should be == master_log.transaction_datetime
      voucher_log.primary_transaction_ref_id.should be == master_log.ref_id
      voucher_log.mobile.should be == @credit_account.mobile
      voucher_log.credit_account_id.should be == @credit_account.id
      voucher_log.denomination.should be == @voucher_meta.denomination
      voucher_log.deducted_amount.should be == 10000
      voucher_log.merchant_num.should be == master_log.merchant_num
      voucher_log.merchant_name.should be == master_log.merchant_name
      voucher_log.merchant_store_id.should be == master_log.merchant_store_id
    end

    it 'should use voucher and revert it' do
      post '/engine/pos/transactions', {bank_card: @bank_card.card_num, merchant_num: @store.merchant_number, money_amount: 15000, plan_type: 'bank_discount'} .merge(platform_account_key_secret)
      response.status.should be == 200
      body = JSON.parse(response.body)
      body['actual_money_amount'].should be == 3500
      body['trans_id'].should_not be_nil
      now = Time.now.localtime.strftime('%Y-%m-%d %H:%M:%S')
      put "/engine/pos/transactions/#{body['trans_id']}", {status: 1,
                                                    transaction_datetime: now,
                                                    sequence_num: '111',
                                                    terminal_num: '222',
                                                    merchant_amount: 997
      }.merge(platform_account_key_secret)
      response.status.should be == 200
      Trade::TransactionLog.count.should be == 1
      master_log = Trade::TransactionLog.primary_log.first
      master_log.credit_delta.should be == 0
      master_log.merchant_rate = @payment_plan_all.merchant_rate
      master_log.merchant_name.should be == @store.name
      master_log.transaction_datetime.localtime.strftime('%Y-%m-%d %H:%M:%S').should be == now
      master_log.log_type.should be == Trade::TransactionLog::PRIMARY
      master_log.transaction_type.should be == Trade::TransactionLog::BANK_DISCOUNT
      master_log.credit_account_id.should be == @credit_account.id
      master_log.sequence_number.should be == '111'
      master_log.terminal_num.should be =='222'
      master_log.merchant_store_id.should be == @store.id
      master_log.media_num.should be == @bank_card.card_num
      master_log.media_type.should be == Member::PaymentMedia::BANK_CARD
      master_log.money_amount.should be == 15000
      master_log.actual_money_amount.should be == 3500
      master_log.mobile.should be == @credit_account.mobile
      master_log.customer_name.should be == @credit_account.name
      master_log.merchant_amount.should be == 997
      master_log.merchant_num.should be == @store.merchant_number
      master_log.plan_type.should be == Pay::PaymentPlan::BANK_DISCOUNT
      master_log.voucher_used_count.should be == 1
      master_log.voucher_deducted_amount.should be == 10000
      master_log.matched_bank.should be == '中国建设银行'
      Trade::Transaction.count.should be == 0

      @credit_account.vouchers.size.should be ==1
      voucher = @credit_account.vouchers.first
      voucher.status.should be == Member::Voucher::USED
      Trade::VoucherTransactionLog.where(transaction_type: Trade::VoucherTransactionLog::USE).count.should be == 1
      voucher_log =Trade::VoucherTransactionLog.where(transaction_type: Trade::VoucherTransactionLog::USE).first
      voucher_log.transaction_datetime.should be == master_log.transaction_datetime
      voucher_log.primary_transaction_ref_id.should be == master_log.ref_id
      voucher_log.mobile.should be == @credit_account.mobile
      voucher_log.credit_account_id.should be == @credit_account.id
      voucher_log.denomination.should be == @voucher_meta.denomination
      voucher_log.deducted_amount.should be == 10000
      voucher_log.merchant_num.should be == master_log.merchant_num
      voucher_log.merchant_name.should be == master_log.merchant_name
      voucher_log.merchant_store_id.should be == master_log.merchant_store_id

      delete "/engine/pos/transactions/#{body['trans_id']}", {reason: 'test'}.merge(platform_account_key_secret)
      response.status.should be == 200
      Trade::TransactionLog.count.should be == 2
      @credit_account.vouchers.size.should be ==1
      voucher = @credit_account.vouchers.first
      voucher.status.should be == Member::Voucher::NOT_USED
      Trade::VoucherTransactionLog.where(transaction_type: Trade::VoucherTransactionLog::USE).count.should be == 0
    end


    it 'should not use voucher if voucher is set as inactive' do
      @voucher_meta.status = Member::VoucherMeta::INACTIVE
      @voucher_meta.save!
      post '/engine/pos/transactions', {bank_card: @bank_card.card_num, merchant_num: @store.merchant_number, money_amount: 15000, plan_type: 'bank_discount'}.merge(platform_account_key_secret)
      response.status.should be == 200
      body = JSON.parse(response.body)
      body['actual_money_amount'].should be == 13500
      put "/engine/pos/transactions/#{body['trans_id']}", {status: 1,
                                                    transaction_datetime: '2013-07-18 15:47:35',
                                                    sequence_num: '111',
                                                    terminal_num: '222',
                                                    merchant_amount: 997
      }.merge(platform_account_key_secret)
      response.status.should be == 200
      Trade::TransactionLog.count.should be == 1
      master_log = Trade::TransactionLog.primary_log.first
      master_log.credit_delta.should be == 0
      master_log.merchant_rate = @payment_plan_all.merchant_rate
      master_log.merchant_name.should be == @store.name
      master_log.transaction_datetime.localtime.strftime('%Y-%m-%d %H:%M:%S').should be =='2013-07-18 15:47:35'
      master_log.log_type.should be == Trade::TransactionLog::PRIMARY
      master_log.transaction_type.should be == Trade::TransactionLog::BANK_DISCOUNT
      master_log.credit_account_id.should be == @credit_account.id
      master_log.sequence_number.should be == '111'
      master_log.terminal_num.should be =='222'
      master_log.merchant_store_id.should be == @store.id
      master_log.media_num.should be == @bank_card.card_num
      master_log.media_type.should be == Member::PaymentMedia::BANK_CARD
      master_log.money_amount.should be == 15000
      master_log.actual_money_amount.should be == 13500
      master_log.mobile.should be == @credit_account.mobile
      master_log.customer_name.should be == @credit_account.name
      master_log.merchant_amount.should be == 997
      master_log.merchant_num.should be == @store.merchant_number
      master_log.plan_type.should be == Pay::PaymentPlan::BANK_DISCOUNT
      master_log.voucher_used_count.should be == 0
      master_log.voucher_deducted_amount.should be == 0
      master_log.matched_bank.should be == '中国建设银行'
      Trade::Transaction.count.should be == 0

      @credit_account.vouchers.size.should be == 1
      voucher = @credit_account.vouchers.first
      voucher.status.should be == Member::Voucher::NOT_USED
      Trade::VoucherTransactionLog.where(transaction_type: Trade::VoucherTransactionLog::USE).count.should be == 0
    end

    it 'should not use voucher if voucher expires' do
      @voucher_meta.valid_till = 1.hour.ago
      @voucher_meta.save!
      post '/engine/pos/transactions', {bank_card: @bank_card.card_num, merchant_num: @store.merchant_number, money_amount: 15000, plan_type: 'bank_discount'}.merge(platform_account_key_secret)
      response.status.should be == 200
      body = JSON.parse(response.body)
      body['actual_money_amount'].should be == 13500
      put "/engine/pos/transactions/#{body['trans_id']}", {status: 1,
                                                    transaction_datetime: '2013-07-18 15:47:35',
                                                    sequence_num: '111',
                                                    terminal_num: '222',
                                                    merchant_amount: 997
      }.merge(platform_account_key_secret)
      response.status.should be == 200
      Trade::TransactionLog.count.should be == 1
      master_log = Trade::TransactionLog.primary_log.first
      master_log.credit_delta.should be == 0
      master_log.merchant_rate = @payment_plan_all.merchant_rate
      master_log.merchant_name.should be == @store.name
      master_log.transaction_datetime.localtime.strftime('%Y-%m-%d %H:%M:%S').should be =='2013-07-18 15:47:35'
      master_log.log_type.should be == Trade::TransactionLog::PRIMARY
      master_log.transaction_type.should be == Trade::TransactionLog::BANK_DISCOUNT
      master_log.credit_account_id.should be == @credit_account.id
      master_log.sequence_number.should be == '111'
      master_log.terminal_num.should be =='222'
      master_log.merchant_store_id.should be == @store.id
      master_log.media_num.should be == @bank_card.card_num
      master_log.media_type.should be == Member::PaymentMedia::BANK_CARD
      master_log.money_amount.should be == 15000
      master_log.actual_money_amount.should be == 13500
      master_log.mobile.should be == @credit_account.mobile
      master_log.customer_name.should be == @credit_account.name
      master_log.merchant_amount.should be == 997
      master_log.merchant_num.should be == @store.merchant_number
      master_log.plan_type.should be == Pay::PaymentPlan::BANK_DISCOUNT
      master_log.voucher_used_count.should be == 0
      master_log.voucher_deducted_amount.should be == 0
      master_log.matched_bank.should be == '中国建设银行'
      Trade::Transaction.count.should be == 0

      @credit_account.vouchers.size.should be == 1
      voucher = @credit_account.vouchers.first
      voucher.status.should be == Member::Voucher::NOT_USED
      Trade::VoucherTransactionLog.where(transaction_type: Trade::VoucherTransactionLog::USE).count.should be == 0
    end

    it 'should not use voucher if payment plan does not accept global voucher' do
      @payment_plan_all.voucher_status = Pay::PaymentPlan::ACCEPT_NONE
      @payment_plan_all.save!
      post '/engine/pos/transactions', {bank_card: @bank_card.card_num, merchant_num: @store.merchant_number, money_amount: 15000, plan_type: 'bank_discount'}.merge(platform_account_key_secret)
      response.status.should be == 200
      body = JSON.parse(response.body)
      body['actual_money_amount'].should be == 13500
      put "/engine/pos/transactions/#{body['trans_id']}", {status: 1,
                                                    transaction_datetime: '2013-07-18 15:47:35',
                                                    sequence_num: '111',
                                                    terminal_num: '222',
                                                    merchant_amount: 997
      }.merge(platform_account_key_secret)
      response.status.should be == 200
      Trade::TransactionLog.count.should be == 1
      master_log = Trade::TransactionLog.primary_log.first
      master_log.credit_delta.should be == 0
      master_log.merchant_rate = @payment_plan_all.merchant_rate
      master_log.merchant_name.should be == @store.name
      master_log.transaction_datetime.localtime.strftime('%Y-%m-%d %H:%M:%S').should be =='2013-07-18 15:47:35'
      master_log.log_type.should be == Trade::TransactionLog::PRIMARY
      master_log.transaction_type.should be == Trade::TransactionLog::BANK_DISCOUNT
      master_log.credit_account_id.should be == @credit_account.id
      master_log.sequence_number.should be == '111'
      master_log.terminal_num.should be =='222'
      master_log.merchant_store_id.should be == @store.id
      master_log.media_num.should be == @bank_card.card_num
      master_log.media_type.should be == Member::PaymentMedia::BANK_CARD
      master_log.money_amount.should be == 15000
      master_log.actual_money_amount.should be == 13500
      master_log.mobile.should be == @credit_account.mobile
      master_log.customer_name.should be == @credit_account.name
      master_log.merchant_amount.should be == 997
      master_log.merchant_num.should be == @store.merchant_number
      master_log.plan_type.should be == Pay::PaymentPlan::BANK_DISCOUNT
      master_log.voucher_used_count.should be == 0
      master_log.voucher_deducted_amount.should be == 0
      master_log.matched_bank.should be == '中国建设银行'
      Trade::Transaction.count.should be == 0

      @credit_account.vouchers.size.should be == 1
      voucher = @credit_account.vouchers.first
      voucher.status.should be == Member::Voucher::NOT_USED
     Trade::VoucherTransactionLog.where(transaction_type:Trade::VoucherTransactionLog::USE).count.should be == 0
    end
  end

  describe 'issue voucher' do
    before :each do
      @voucher_meta = Member::VoucherMeta.create!(denomination: 10000, status: Member::VoucherMeta::ACTIVE)
      @marketing_rule = create(:transaction_rule, :valid, merchant_store: @store)
      @post_action = create(:voucher_action, voucher_meta: @voucher_meta, marketing_rule: @marketing_rule)
      @payment_plan_all = create(:bank_discount, discount_rate: 0.1, merchant_rate: 0.03, merchant_store: @store, marketing_rules: [@marketing_rule])
    end

    it 'should issue voucher' do
      SmsWorker.should_receive(:perform_async).with(@credit_account.mobile, anything)
      post '/engine/pos/transactions', {bank_card: @bank_card.card_num, merchant_num: @store.merchant_number, money_amount: 15000, plan_type: 'bank_discount'}.merge(platform_account_key_secret)
      response.status.should be == 200
      body = JSON.parse(response.body)
      body['actual_money_amount'].should be == 13500
      now = Time.now.localtime.strftime('%Y-%m-%d %H:%M:%S')
      put "/engine/pos/transactions/#{body['trans_id']}", {status: 1,
                                                    transaction_datetime: now,
                                                    sequence_num: '111',
                                                    terminal_num: '222',
                                                    merchant_amount: 997
      }.merge(platform_account_key_secret)
      response.status.should be == 200
      Trade::TransactionLog.count.should be == 1
      master_log = Trade::TransactionLog.primary_log.first
      master_log.credit_delta.should be == 0
      master_log.merchant_rate = @payment_plan_all.merchant_rate
      master_log.merchant_name.should be == @store.name
      master_log.transaction_datetime.localtime.strftime('%Y-%m-%d %H:%M:%S').should be == now
      master_log.log_type.should be == Trade::TransactionLog::PRIMARY
      master_log.transaction_type.should be == Trade::TransactionLog::BANK_DISCOUNT
      master_log.credit_account_id.should be == @credit_account.id
      master_log.sequence_number.should be == '111'
      master_log.terminal_num.should be =='222'
      master_log.merchant_store_id.should be == @store.id
      master_log.media_num.should be == @bank_card.card_num
      master_log.media_type.should be == Member::PaymentMedia::BANK_CARD
      master_log.money_amount.should be == 15000
      master_log.actual_money_amount.should be == 13500
      master_log.mobile.should be == @credit_account.mobile
      master_log.customer_name.should be == @credit_account.name
      master_log.merchant_amount.should be == 997
      master_log.merchant_num.should be == @store.merchant_number
      master_log.plan_type.should be == Pay::PaymentPlan::BANK_DISCOUNT
      master_log.voucher_used_count.should be == 0
      master_log.voucher_deducted_amount.should be == 0
      master_log.matched_bank.should be == '中国建设银行'
      Trade::Transaction.count.should be == 0

      @credit_account.vouchers.size.should be == 1
      voucher = @credit_account.vouchers.first
      voucher.status.should be == Member::Voucher::NOT_USED
      voucher_log =Trade::VoucherTransactionLog.where(transaction_type:Trade::VoucherTransactionLog::ISSUE).first
      voucher_log.should_not be_nil
      voucher_log.primary_transaction_ref_id.should be == master_log.ref_id
      voucher_log.transaction_datetime.should be == master_log.transaction_datetime
      voucher_log.issue_event.should be ==Trade::VoucherTransactionLog::CONSUMPTION
      voucher_log.merchant_num.should be == master_log.merchant_num
      voucher_log.merchant_name.should be == master_log.merchant_name
      voucher_log.merchant_store_id.should be == master_log.merchant_store_id

    end

    it 'should not issue voucher if post action is inactive' do
      @marketing_rule.update(status: Rule::INACTIVE)
      SmsWorker.should_not_receive(:perform_async).with(@credit_account.mobile, anything)
      post '/engine/pos/transactions', {bank_card: @bank_card.card_num, merchant_num: @store.merchant_number, money_amount: 15000, plan_type: 'bank_discount'}.merge(platform_account_key_secret)
      response.status.should be == 200
      body = JSON.parse(response.body)
      body['actual_money_amount'].should be == 13500
      now = Time.now.localtime.strftime('%Y-%m-%d %H:%M:%S')
      put "/engine/pos/transactions/#{body['trans_id']}", {status: 1,
                                                    transaction_datetime: now,
                                                    sequence_num: '111',
                                                    terminal_num: '222',
                                                    merchant_amount: 997
      }.merge(platform_account_key_secret)
      response.status.should be == 200
      Trade::TransactionLog.count.should be == 1
      Trade::Transaction.count.should be == 0

      @credit_account.vouchers.size.should be == 0
    end
  end

  describe 'with rule for referee' do
    before :each do
      @payment_plan_all = create(:bank_discount, discount_rate: 0.1, minimal_money_amount: 400, merchant_store: @store, referer_rate: 0.03)
      @payment_plan_for_referee = create(:bank_discount, :rule_for_referee, merchant_rate: 0.078, discount_rate: 0.1, minimal_money_amount: 400, merchant_store: @store, referer_rate: 0.03)
      @credit_account_with_referer = create(:individual_credit_account, bank_card: '1111288888888888888888888', mobile: '1112233', referer_account: @credit_account)
      @credit_account_with_store_referer = create(:individual_credit_account, bank_card: '11113888888888888', referer_account: @store.credit_account)
    end

    it 'should select payment plan that does not matches referee rule' do
      post '/engine/pos/transactions', {bank_card: @credit_account_with_referer.bank_cards.first.card_num, merchant_num: @store.merchant_number, money_amount: 1000, plan_type: 'bank_discount'}.merge(platform_account_key_secret)
      response.status.should be == 200
      body = JSON.parse(response.body)
      put "/engine/pos/transactions/#{body['trans_id']}", {status: 1,
                                                    transaction_datetime: '2013-07-18 15:47:35',
                                                    sequence_num: '111',
                                                    terminal_num: '222',
                                                    merchant_amount: 997
      }.merge(platform_account_key_secret)
      response.status.should be == 200
      Trade::TransactionLog.primary_log.count.should be == 1
      master_log = Trade::TransactionLog.primary_log.first
      master_log.credit_delta.should be == 0
      master_log.merchant_rate = @payment_plan_all.merchant_rate
      master_log.merchant_name.should be == @store.name
      master_log.transaction_datetime.localtime.strftime('%Y-%m-%d %H:%M:%S').should be =='2013-07-18 15:47:35'
      master_log.log_type.should be == Trade::TransactionLog::PRIMARY
      master_log.transaction_type.should be == Trade::TransactionLog::BANK_DISCOUNT
      master_log.credit_account_id.should be == @credit_account_with_referer.id
      master_log.sequence_number.should be == '111'
      master_log.terminal_num.should be =='222'
      master_log.merchant_store_id.should be == @store.id
      master_log.media_num.should be == @credit_account_with_referer.bank_cards.first.card_num
      master_log.media_type.should be == Member::PaymentMedia::BANK_CARD
      master_log.money_amount.should be == 1000
      master_log.actual_money_amount.should be == 900
      master_log.mobile.should be == @credit_account_with_referer.mobile
      master_log.customer_name.should be == @credit_account_with_referer.name
      master_log.merchant_amount.should be == 997
      master_log.merchant_num.should be == @store.merchant_number
      master_log.plan_type.should be == Pay::PaymentPlan::BANK_DISCOUNT
      master_log.matched_bank.should be_nil
      Trade::Transaction.count.should be == 0
    end

    it 'should select payment plan that matches referee rule' do
      post '/engine/pos/transactions', {bank_card: @credit_account_with_store_referer.bank_cards.first.card_num, merchant_num: @store.merchant_number, money_amount: 1000, plan_type: 'bank_discount'}.merge(platform_account_key_secret)
      response.status.should be == 200
      body = JSON.parse(response.body)
      put "/engine/pos/transactions/#{body['trans_id']}", {status: 1,
                                                    transaction_datetime: '2013-07-18 15:47:35',
                                                    sequence_num: '111',
                                                    terminal_num: '222',
                                                    merchant_amount: 997
      }.merge(platform_account_key_secret)
      response.status.should be == 200
      Trade::TransactionLog.primary_log.count.should be == 1
      master_log = Trade::TransactionLog.primary_log.first
      master_log.credit_delta.should be == 0
      master_log.merchant_rate = @payment_plan_for_referee.merchant_rate
      master_log.merchant_name.should be == @store.name
      master_log.transaction_datetime.localtime.strftime('%Y-%m-%d %H:%M:%S').should be =='2013-07-18 15:47:35'
      master_log.log_type.should be == Trade::TransactionLog::PRIMARY
      master_log.transaction_type.should be == Trade::TransactionLog::BANK_DISCOUNT
      master_log.credit_account_id.should be == @credit_account_with_store_referer.id
      master_log.sequence_number.should be == '111'
      master_log.terminal_num.should be =='222'
      master_log.merchant_store_id.should be == @store.id
      master_log.media_num.should be == @credit_account_with_store_referer.bank_cards.first.card_num
      master_log.media_type.should be == Member::PaymentMedia::BANK_CARD
      master_log.money_amount.should be == 1000
      master_log.actual_money_amount.should be == 900
      master_log.mobile.should be == @credit_account_with_store_referer.mobile
      master_log.customer_name.should be == @credit_account_with_store_referer.name
      master_log.merchant_amount.should be == 997
      master_log.merchant_num.should be == @store.merchant_number
      master_log.plan_type.should be == Pay::PaymentPlan::BANK_DISCOUNT
      master_log.matched_bank.should be_nil
      Trade::Transaction.count.should be == 0
    end
  end
end
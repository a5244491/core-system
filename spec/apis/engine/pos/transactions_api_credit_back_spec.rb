require 'spec_helper'

describe Engine::POS::TransactionsAPI do
  before :each do
    @store = create(:merchant_store, :active)
    @credit_account = create(:individual_credit_account, mobile: '13981842941', bank_card: '1234567812345678')
    @bank_card = @credit_account.bank_cards.first
    @payment_plan = create(:credit_back, customer_rate: 0.1, merchant_rate: 0.15, referer_rate: 0.03, merchant_store: @store)
  end

  describe 'create transaction' do
    it 'should create transaction' do
      post '/engine/pos/transactions', {bank_card: @bank_card.card_num, merchant_num: @store.merchant_number, money_amount: 1000, plan_type: 'credit_back'}.merge(platform_account_key_secret)
      response.status.should be == 200
      body = JSON.parse(response.body)
      body['actual_money_amount'].should be == 1000
      body['merchant_rate'].should be == '0.15'
      body['trans_id'].should_not be_nil
      body['plan_id'].should be == @payment_plan.id
      body['receipt']['transaction_type'].should be == Pay::CreditBack.new.plan_name
      body['receipt']['footer_m'].should_not be_nil
      body['receipt']['extra_rows_m'].should_not be_nil
      body['receipt']['extra_rows'].should_not be_nil
      body['receipt']['footer_m'].should_not be_nil

      transaction = Trade::Transaction.first
      transaction.actual_money_amount.should be == 1000
      transaction.money_amount.should be == 1000
      transaction.consumer_credit.should be == 100
      transaction.referer_credit.should be == 30
      transaction.transaction_type.should be == Pay::PaymentPlan::CREDIT_BACK
      transaction.payment_plan_id.should be == @payment_plan.id
      transaction.credit_account_id.should be == @credit_account.id
      transaction.merchant_store_id.should be == @store.id
      transaction.mobile.should be == @credit_account.mobile
      transaction.customer_name.should be == @credit_account.name
      transaction.media_type.should be == Member::PaymentMedia::BANK_CARD
      transaction.media_num.should be == '1234567812345678'
      transaction.merchant_name.should be == @store.name
    end

    it 'should not create transaction for non member card' do
      post '/engine/pos/transactions', {bank_card: 'non-member-card', merchant_num: @store.merchant_number, money_amount: 1000, plan_type: 'credit_back', status: Pay::PaymentPlan::VALID}.merge(platform_account_key_secret)
      response.status.should be == 419
      body = JSON.parse(response.body)
      body['screen_msg'].should be == Pay::PaymentPlanError::NOT_MEMBER_CARD
    end
  end
  describe 'finish transaction' do
    it 'should finish transaction' do
      post '/engine/pos/transactions', {bank_card: @bank_card.card_num, merchant_num: @store.merchant_number, money_amount: 1000, plan_type: 'credit_back'}.merge(platform_account_key_secret)
      response.status.should be == 200
      body = JSON.parse(response.body)
      put "/engine/pos/transactions/#{body['trans_id']}", {status: 1,
                                                    transaction_datetime: '2013-07-18 15:47:35',
                                                    sequence_num: '111',
                                                    terminal_num: '222',
                                                    merchant_amount: 850
      }.merge(platform_account_key_secret)
      response.status.should be == 200
      @credit_account.bank_cards.first.credit_earned.should be == 100
      Trade::TransactionLog.count.should be == 1
      master_log = Trade::TransactionLog.primary_log.first
      master_log.credit_delta.should be == 100
      master_log.merchant_name.should be == @store.name
      master_log.transaction_datetime.localtime.strftime('%Y-%m-%d %H:%M:%S').should be =='2013-07-18 15:47:35'
      master_log.log_type.should be == Trade::TransactionLog::PRIMARY
      master_log.transaction_type.should be == Trade::TransactionLog::CREDIT_BACK
      master_log.credit_account_id.should be == @credit_account.id
      master_log.mobile.should be == @credit_account.mobile
      master_log.sequence_number.should be == '111'
      master_log.terminal_num.should be =='222'
      master_log.actual_money_amount.should be == 1000
      master_log.merchant_store_id.should be == @store.id
      master_log.media_num.should be == '1234567812345678'
      master_log.media_type.should be == Member::PaymentMedia::BANK_CARD
      master_log.money_amount.should be == 1000
      master_log.actual_money_amount.should be == 1000
      master_log.mobile.should be == @credit_account.mobile
      master_log.customer_name.should be == @credit_account.name
      master_log.merchant_num.should be == @store.merchant_number
      master_log.merchant_amount.should be == 850
      master_log.plan_type.should be == Pay::PaymentPlan::CREDIT_BACK
      master_log.merchant_rate.should be == @payment_plan.merchant_rate

      @credit_account = Member::IndividualCreditAccount.find(@credit_account.id)
      @credit_account.total_credit.should be == 100
      @credit_account.usable_credit.should be == 100
      @credit_account.consumption_credit.should be == 100
      @credit_account.consumption_times.should be == 1

      Trade::Transaction.count.should be == 0
    end
  end

  describe 'revert transaction' do
    it 'should revert transaction' do
      post '/engine/pos/transactions', {bank_card: @bank_card.card_num, merchant_num: @store.merchant_number, money_amount: 1000, plan_type: 'credit_back'}.merge(platform_account_key_secret)
      response.status.should be == 200
      body = JSON.parse(response.body)
      now = Time.now.localtime.strftime('%Y-%m-%d %H:%M:%S')
      put "/engine/pos/transactions/#{body['trans_id']}", {status: 1,
                                                    transaction_datetime: now,
                                                    sequence_num: '111',
                                                    terminal_num: '222',
                                                    merchant_amount: 850
      }.merge(platform_account_key_secret)
      response.status.should be == 200
      delete "/engine/pos/transactions/#{body['trans_id']}", {reason: 'test'}.merge(platform_account_key_secret)
      response.status.should be == 200
      @credit_account.bank_cards.first.credit_earned.should be == 0
      Trade::TransactionLog.count.should be == 2
      reverted_log = Trade::TransactionLog.where(status: Trade::TransactionLog::REVERTED).first
      reverted_log.should_not be_nil
      reverted_log.credit_delta.should be == -100
      reverted_log.actual_money_amount.should be == -1000
      reverted_log.merchant_amount.should be == -850
      @credit_account = Member::IndividualCreditAccount.find(@credit_account.id)
      @credit_account.total_credit.should be == 0
      @credit_account.usable_credit.should be == 0
      @credit_account.consumption_credit.should be == 0
      @credit_account.consumption_times.should be == 0

      delete "/engine/pos/transactions/#{body['trans_id']}", {reason: 'test'}.merge(platform_account_key_secret)
      response.status.should be == 200
      Trade::TransactionLog.count.should be == 2
    end
  end

  describe 'cancel transaction' do
    it 'should cancel transaction' do
      post '/engine/pos/transactions', {bank_card: @bank_card.card_num, merchant_num: @store.merchant_number, money_amount: 1000, plan_type: 'credit_back'}.merge(platform_account_key_secret)
      response.status.should be == 200
      body = JSON.parse(response.body)
      put "/engine/pos/transactions/#{body['trans_id']}", {status: 0, merchant_num: @store.merchant_number}.merge(platform_account_key_secret)
      response.status.should be == 200
      Trade::Transaction.count.should be == 0
      Trade::TransactionLog.count.should be == 0
    end
  end

  describe 'with referer' do
    before :each do
      @referer_account = create(:individual_credit_account, mobile: '13981842942', name: 'test2')
      @credit_account.referer_account = @referer_account
      @credit_account.save!
      System::Configuration.set(System::Configuration::REFERER_RATE, '0.01')
    end
    it 'should finish transaction' do
      post '/engine/pos/transactions', {bank_card: @bank_card.card_num, merchant_num: @store.merchant_number, money_amount: 1000, plan_type: 'credit_back'}.merge(platform_account_key_secret)
      response.status.should be == 200
      body = JSON.parse(response.body)
      put "/engine/pos/transactions/#{body['trans_id']}", {status: 1,
                                                    transaction_datetime: '2013-07-18 15:47:35',
                                                    sequence_num: '111',
                                                    terminal_num: '222',
                                                    merchant_amount: 850
      }.merge(platform_account_key_secret)
      response.status.should be == 200
      @credit_account.bank_cards.first.credit_earned.should be == 100
      Trade::TransactionLog.count.should be == 2
      master_log = Trade::TransactionLog.primary_log.first
      master_log.credit_delta.should be == 100
      master_log.merchant_name.should be == @store.name
      master_log.transaction_datetime.localtime.strftime('%Y-%m-%d %H:%M:%S').should be =='2013-07-18 15:47:35'
      master_log.log_type.should be == Trade::TransactionLog::PRIMARY
      master_log.transaction_type.should be == Trade::TransactionLog::CREDIT_BACK
      master_log.credit_account_id.should be == @credit_account.id
      master_log.mobile.should be == @credit_account.mobile
      master_log.sequence_number.should be == '111'
      master_log.terminal_num.should be =='222'
      master_log.actual_money_amount.should be == 1000
      master_log.merchant_store_id.should be == @store.id
      master_log.media_num.should be == '1234567812345678'
      master_log.media_type.should be == Member::PaymentMedia::BANK_CARD
      master_log.money_amount.should be == 1000
      master_log.actual_money_amount.should be == 1000
      master_log.mobile.should be == @credit_account.mobile
      master_log.customer_name.should be == @credit_account.name
      master_log.credit_account_external_id.should be == @credit_account.external_id
      master_log.merchant_num.should be == @store.merchant_number
      master_log.merchant_amount.should be == 850
      master_log.plan_type.should be == Pay::PaymentPlan::CREDIT_BACK

      vice_log = Trade::TransactionLog.vice_log.first
      vice_log.credit_delta.should be == 30
      vice_log.merchant_name.should be == @store.name
      vice_log.transaction_datetime.localtime.strftime('%Y-%m-%d %H:%M:%S').should be =='2013-07-18 15:47:35'
      vice_log.log_type.should be == Trade::TransactionLog::VICE
      vice_log.transaction_type.should be == 'referer_credit'
      vice_log.credit_account_id.should be == @referer_account.id
      vice_log.sequence_number.should be == '111'
      vice_log.terminal_num.should be =='222'
      vice_log.actual_money_amount.should be == 0
      vice_log.merchant_store_id.should be == @store.id
      vice_log.media_num.should be == '1234567812345678'
      vice_log.media_type.should be == Member::PaymentMedia::BANK_CARD
      vice_log.money_amount.should be == 0
      vice_log.actual_money_amount.should be == 0
      vice_log.mobile.should be == @referer_account.mobile
      vice_log.customer_name.should be == @referer_account.name
      vice_log.credit_account_external_id.should be == @referer_account.external_id
      vice_log.merchant_num.should be == @store.merchant_number
      vice_log.merchant_amount.should be == 0
      vice_log.plan_type.should be == Pay::PaymentPlan::CREDIT_BACK

      @referer_account = Member::IndividualCreditAccount.find(@referer_account.id)
      @referer_account.total_credit.should be == 30
      @referer_account.usable_credit.should be == 30
      @referer_account.consumption_credit.should be == 0
      @referer_account.consumption_times.should be == 0
      Trade::Transaction.count.should be == 0
    end
    it 'should revert transaction' do
      post '/engine/pos/transactions', {bank_card: @bank_card.card_num, merchant_num: @store.merchant_number, money_amount: 1000, plan_type: 'credit_back'}.merge(platform_account_key_secret)
      response.status.should be == 200
      body = JSON.parse(response.body)
      now = Time.now.localtime.strftime('%Y-%m-%d %H:%M:%S')
      put "/engine/pos/transactions/#{body['trans_id']}", {status: 1,
                                                    transaction_datetime: now,
                                                    sequence_num: '111',
                                                    terminal_num: '222',
                                                    merchant_amount: 850
      }.merge(platform_account_key_secret)
      response.status.should be == 200
      delete "/engine/pos/transactions/#{body['trans_id']}", {reason: 'test'}.merge(platform_account_key_secret)
      response.status.should be == 200
      @credit_account.bank_cards.first.credit_earned.should be == 0
      Trade::TransactionLog.count.should be == 4
      reverted_master_log = Trade::TransactionLog.where(status: Trade::TransactionLog::REVERTED, log_type: Trade::TransactionLog::PRIMARY).first
      reverted_master_log.should_not be_nil
      reverted_master_log.credit_delta.should be == -100
      reverted_master_log.actual_money_amount.should be == -1000
      reverted_master_log.merchant_amount.should be == -850
      @credit_account = Member::IndividualCreditAccount.find(@credit_account.id)
      @credit_account.total_credit.should be == 0
      @credit_account.usable_credit.should be == 0
      @credit_account.consumption_credit.should be == 0
      @credit_account.consumption_times.should be == 0

      reverted_vice_log = Trade::TransactionLog.where(status: Trade::TransactionLog::REVERTED, log_type: Trade::TransactionLog::VICE).first
      reverted_vice_log.should_not be_nil
      reverted_vice_log.credit_delta.should be == -30
      reverted_vice_log.actual_money_amount.should be == 0
      reverted_vice_log.merchant_amount.should be == 0
      @referer_account = Member::IndividualCreditAccount.find(@referer_account.id)
      @referer_account.total_credit.should be == 0
      @referer_account.usable_credit.should be == 0
      @referer_account.consumption_credit.should be == 0
      @referer_account.consumption_times.should be == 0

      delete "/engine/pos/transactions/#{body['trans_id']}", {reason: 'test'}.merge(platform_account_key_secret)
      response.status.should be == 200
      Trade::TransactionLog.count.should be == 4
    end
  end

  describe 'with voucher' do
    before :each do
      @voucher_meta = Member::VoucherMeta.create!(denomination: 10000, status: Member::VoucherMeta::ACTIVE)
      @credit_account.issue_voucher(@voucher_meta.code)
    end

    it 'should use voucher' do
      post '/engine/pos/transactions', {bank_card: @bank_card.card_num, merchant_num: @store.merchant_number, money_amount: 12000, plan_type: 'credit_back'}.merge(platform_account_key_secret)
      response.status.should be == 200
      body = JSON.parse(response.body)
      put "/engine/pos/transactions/#{body['trans_id']}", {status: 1,
                                                    transaction_datetime: '2013-07-18 15:47:35',
                                                    sequence_num: '111',
                                                    terminal_num: '222',
                                                    merchant_amount: 850
      }.merge(platform_account_key_secret)
      response.status.should be == 200
      Trade::TransactionLog.count.should be == 1
      master_log = Trade::TransactionLog.primary_log.first
      master_log.credit_delta.should be == 200
      master_log.merchant_name.should be == @store.name
      master_log.transaction_datetime.localtime.strftime('%Y-%m-%d %H:%M:%S').should be =='2013-07-18 15:47:35'
      master_log.log_type.should be == Trade::TransactionLog::PRIMARY
      master_log.transaction_type.should be == Trade::TransactionLog::CREDIT_BACK
      master_log.credit_account_id.should be == @credit_account.id
      master_log.mobile.should be == @credit_account.mobile
      master_log.sequence_number.should be == '111'
      master_log.terminal_num.should be =='222'
      master_log.actual_money_amount.should be == 2000
      master_log.merchant_store_id.should be == @store.id
      master_log.media_num.should be == '1234567812345678'
      master_log.media_type.should be == Member::PaymentMedia::BANK_CARD
      master_log.money_amount.should be == 12000
      master_log.actual_money_amount.should be == 2000
      master_log.mobile.should be == @credit_account.mobile
      master_log.customer_name.should be == @credit_account.name
      master_log.merchant_num.should be == @store.merchant_number
      master_log.merchant_amount.should be == 850
      master_log.plan_type.should be == Pay::PaymentPlan::CREDIT_BACK
      master_log.merchant_rate.should be == @payment_plan.merchant_rate

      @credit_account = Member::IndividualCreditAccount.find(@credit_account.id)
      @credit_account.total_credit.should be == 200
      @credit_account.usable_credit.should be == 200
      @credit_account.consumption_credit.should be == 200
      @credit_account.consumption_times.should be == 1

      Trade::Transaction.count.should be == 0

      @credit_account.vouchers.size.should be ==1
      voucher = @credit_account.vouchers.first
      voucher.status.should be == Member::Voucher::USED
      Trade::VoucherTransactionLog.where(transaction_type:  Trade::VoucherTransactionLog::USE).count.should be == 1
      voucher_log = Trade::VoucherTransactionLog.where(transaction_type:  Trade::VoucherTransactionLog::USE).first
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
  end

end
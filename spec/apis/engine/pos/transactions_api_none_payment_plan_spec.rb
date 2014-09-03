require 'spec_helper'

describe Engine::POS::TransactionsAPI do
  before :each do
    @store = create(:merchant_store, :active, acquirer: {acquirer_name: 'test1', acquirer_code: '11111111'}, tag: 'test2')
    @payment_plan = @store.payment_plans.first
    @credit_account = create(:individual_credit_account, mobile: '13981842941', name: 'testxx', tag: 'test1', bank_card: '1234567812345678')
    System::Configuration.set(System::Configuration::REFERER_RATE, 0.01)
    @referer_account = create(:individual_credit_account, mobile: '13981842942', name: 'test2', tag: 'test1')
    @credit_account.referer_account = @referer_account
    @credit_account.save!
    @bank_card = @credit_account.bank_cards.first
    @acquirer = @store.acquire_org
  end


  it 'should perform transaction for member card' do
    post '/engine/pos/transactions', {bank_card: @bank_card.card_num, merchant_num: @store.merchant_number, money_amount: 1000, plan_type: 'none'}, platform_account_header
    response.status.should be == 200
    body = JSON.parse(response.body)
    body['actual_money_amount'].should be == 1000
    body['trans_id'].should_not be_nil
    body['plan_id'].should be == @payment_plan.id
    body['receipt']['transaction_type'].should be == Pay::NonePaymentPlan.new.plan_name
    body['receipt']['footer_m'].should_not be_nil
    body['receipt']['extra_rows_m'].should_not be_nil
    body['receipt']['extra_rows'].should_not be_nil
    body['receipt']['footer_m'].should_not be_nil

    transaction = Trade::Transaction.first
    transaction.actual_money_amount.should be == 1000
    transaction.money_amount.should be == 1000
    transaction.transaction_type.should be == Pay::PaymentPlan::NONE
    transaction.payment_plan_id.should be == @payment_plan.id
    transaction.credit_account_id.should be == @credit_account.id
    transaction.merchant_store_id.should be == @store.id
    transaction.mobile.should be == @credit_account.mobile
    transaction.customer_name.should be == @credit_account.name
    transaction.media_type.should be == Member::PaymentMedia::BANK_CARD
    transaction.media_num.should be == @bank_card.card_num
    transaction.merchant_name.should be == @store.name
    transaction.acquirer_code.should be == @acquirer.acquirer_code
    @credit_account.consumption_times.should be == 0

    put "/engine/pos/transactions/#{body['trans_id']}", {status: 1,
                                                  transaction_datetime: '2013-07-18 15:47:35',
                                                  sequence_num: '111',
                                                  terminal_num: '222',
                                                  merchant_amount: 850
    }, platform_account_header
    response.status.should be == 200
    #sleep(3)

    Trade::TransactionLog.count.should be == 1
    master_log = Trade::TransactionLog.primary_log.first
    master_log.credit_delta.should be == 0
    master_log.merchant_name.should be == @store.name
    master_log.transaction_datetime.localtime.strftime('%Y-%m-%d %H:%M:%S').should be =='2013-07-18 15:47:35'
    master_log.log_type.should be == Trade::TransactionLog::PRIMARY
    master_log.transaction_type.should be == Trade::TransactionLog::NONE
    master_log.credit_account_id.should be == @credit_account.id
    master_log.mobile.should be == @credit_account.mobile
    master_log.sequence_number.should be == '111'
    master_log.terminal_num.should be =='222'
    master_log.actual_money_amount.should be == 1000
    master_log.merchant_store_id.should be == @store.id
    master_log.media_num.should be == @bank_card.card_num
    master_log.media_type.should be == Member::PaymentMedia::BANK_CARD
    master_log.money_amount.should be == 1000
    master_log.actual_money_amount.should be == 1000
    master_log.mobile.should be == @credit_account.mobile
    master_log.customer_name.should be == @credit_account.name
    master_log.merchant_amount.should be == 850
    master_log.merchant_num.should be == @store.merchant_number
    master_log.plan_type.should be == Pay::PaymentPlan::NONE
    master_log.ref_id.should be == body['trans_id']
    master_log.acquirer_code.should be == @acquirer.acquirer_code
    master_log.user_tag.should be == @credit_account.tag
    master_log.merchant_tag.should be == @store.tag
    master_log.merchant_rate.should be_nil
    master_log.referer_id.should be == @credit_account.referer_account.id
    master_log.referer_external_id.should be == @credit_account.referer_account.external_id
    master_log.referer_mobile.should be == @credit_account.referer_account.mobile
    Trade::Transaction.count.should be == 0
    @credit_account.reload
    @credit_account.consumption_times.should be == 1
  end

  it 'should perform transaction for member card, wrong transaction date' do
    post '/engine/pos/transactions', {bank_card: @bank_card.card_num, merchant_num: @store.merchant_number, money_amount: 1000, plan_type: 'none'}, platform_account_header
    response.status.should be == 200
    body = JSON.parse(response.body)
    body['trans_id'].should_not be_nil
    put "/engine/pos/transactions/#{body['trans_id']}", {status: 1,
                                                  transaction_datetime: '2013-07-18 xxx15:47:35',
                                                  sequence_num: '111',
                                                  terminal_num: '222',
                                                  merchant_amount: 850
    }, platform_account_header
    response.status.should be == 200

    Trade::TransactionLog.count.should be == 1
    master_log = Trade::TransactionLog.primary_log.first
    master_log.transaction_datetime.should_not be_nil
  end

  it 'should perform transaction for member card, blank transaction date' do
    post '/engine/pos/transactions', {bank_card: @bank_card.card_num, merchant_num: @store.merchant_number, money_amount: 1000, plan_type: 'none'}, platform_account_header
    response.status.should be == 200
    body = JSON.parse(response.body)
    body['trans_id'].should_not be_nil
    put "/engine/pos/transactions/#{body['trans_id']}", {status: 1,
                                                  transaction_datetime: '2013-07-18 15:47:35',
                                                  sequence_num: '111',
                                                  terminal_num: '222',
                                                  merchant_amount: 850
    }, platform_account_header
    response.status.should be == 200
    Trade::TransactionLog.count.should be == 1
    master_log = Trade::TransactionLog.primary_log.first
    master_log.transaction_datetime.localtime.should be == DateTime.strptime('2013-07-18 15:47:35 +08:00', '%Y-%m-%d %H:%M:%S %z')
  end

  describe 'revert transaction' do
    it 'should revert transaction' do
      post '/engine/pos/transactions', {bank_card: @bank_card.card_num, merchant_num: @store.merchant_number, money_amount: 1000, plan_type: 'none'}, platform_account_header
      response.status.should be == 200
      body = JSON.parse(response.body)
      trans_id = body['trans_id']
      now = Time.now.localtime.strftime('%Y-%m-%d %H:%M:%S')
      put "/engine/pos/transactions/#{trans_id}", {status: 1,
                                            transaction_datetime: now,
                                            sequence_num: '111',
                                            terminal_num: '222',
                                            merchant_amount: 850
      }, platform_account_header
      response.status.should be == 200
      delete "/engine/pos/transactions/#{trans_id}", {reason: 'test'}, platform_account_header
      response.status.should be == 200
      Trade::TransactionLog.count.should be == 2
      reverted_log = Trade::TransactionLog.where(status: Trade::TransactionLog::REVERTED).first
      reverted_log.should_not be_nil
      reverted_log.actual_money_amount.should be == -1000
      reverted_log.merchant_amount.should be == -850
      reverted_log.money_amount.should be == -1000
      reverted_log.transaction_datetime.localtime.strftime('%Y-%m-%d %H:%M:%S').should be == now

      delete "/engine/pos/transactions/#{trans_id}", {reason: 'test'}, platform_account_header
      response.status.should be == 200
      Trade::TransactionLog.count.should be == 2
    end

    it 'should not revert non-existing transaction' do
      delete '/engine/pos/transactions/not-existing', {reason: 'test'}, platform_account_header
      response.status.should be == 200
      Trade::Transaction.count.should be == 0
      Trade::TransactionLog.count.should be == 0
      Trade::TransactionLog.where(status: Trade::TransactionLog::REVERTED).first.should be_nil
    end
  end

  describe 'with vouchers' do
    before :each do
      @voucher_meta = Member::VoucherMeta.create!(denomination: 10000, status: Member::VoucherMeta::ACTIVE)
      @credit_account.issue_voucher(@voucher_meta.code)
    end

    it 'should not use voucher' do
      post '/engine/pos/transactions', {bank_card: @bank_card.card_num, merchant_num: @store.merchant_number, money_amount: 1000, plan_type: 'none'}, platform_account_header
      response.status.should be == 200
      body = JSON.parse(response.body)
      body['trans_id'].should_not be_nil
      body['actual_money_amount'].should be == 1000
      put "/engine/pos/transactions/#{body['trans_id']}", {status: 1,
                                                    transaction_datetime: '2013-07-18 15:47:35',
                                                    sequence_num: '111',
                                                    terminal_num: '222',
                                                    merchant_amount: 850
      }, platform_account_header
      response.status.should be == 200
      Trade::TransactionLog.count.should be == 1
      master_log = Trade::TransactionLog.primary_log.first
      master_log.actual_money_amount.should be == 1000
      @credit_account.vouchers.not_used.count.should be == 1
      Trade::VoucherTransactionLog.where(transaction_type: Trade::VoucherTransactionLog::USE).count.should be == 0
    end
  end
end
#encoding:utf-8
require 'spec_helper'

describe Engine::POS::MembersAPI do
  before :each do
    @store = create(:merchant_store, :active)
    @store_account = @store.credit_account
    create(:card_bin, bank_bin: '622575', bank_name: '中国招商银行', card_type: Bank::CardBin::CREDIT)
  end

  describe 'register new member' do
     it 'should not register new member if mobile number is invalid' do
       post '/engine/pos/members', {merchant_num: @store.merchant_number, mobile: '1111', bank_card: '6225751111111111111'}.merge(platform_account_key_secret)
       response.status.should be == 419
       body = JSON.parse(response.body)
       body['screen_msg'].should be == MessageProperties::INVALID_MOBILE
     end

     it 'should not register new member if bank_card is missing' do
       post '/engine/pos/members', {merchant_num: @store.merchant_number, mobile: '1111'}.merge(platform_account_key_secret)
       response.status.should be == 400
     end

     it 'should not register new member if mobile is missing' do
       post '/engine/pos/members', {merchant_num: @store.merchant_number, bank_card: '6225751111111111111'}.merge(platform_account_key_secret)
       response.status.should be == 400
     end

     it 'should register new member' do
       SmsWorker.any_instance.should_receive(:perform).with('13981842941', '您已成功绑定尾号为1111的银行卡，可使用该卡立享爱刷超值服务。请访问www.aishua.cn注册账号管理和使用积分【爱刷】', 100)
       post '/engine/pos/members', {merchant_num: @store.merchant_number, mobile: '13981842941', bank_card: '6225751111111111111'}.merge(platform_account_key_secret)
       response.status.should be == 200
       body = JSON.parse(response.body)
       body['receipt']['transaction_type'].should be == MessageProperties::TRAN_TYPE_NEW_MEMBER
       body['receipt']['footer_m'].should_not be_nil
       body['receipt']['extra_rows_m'].should_not be_nil
       body['receipt']['extra_rows'].should_not be_nil
       body['receipt']['footer_m'].should_not be_nil

       credit_account = Member::IndividualCreditAccount.where(mobile: '13981842941').first
       credit_account.status.should be == Member::CreditAccount::INACTIVATED
       credit_account.should_not be_nil
       credit_account.bank_cards.count.should be == 1
       credit_account.bank_cards.first.card_num.should be == '6225751111111111111'
       credit_account.bank_cards.first.card_type.should be == Member::BankCard::CREDIT_CARD
       credit_account.bank_cards.first.bank_name.should be == '中国招商银行'
       credit_account.referer_account.id.should be == @store_account.id
       credit_account.merchant_stores.size.should be == 1
       credit_account.merchant_stores.first.should be == @store
     end

     it 'should register new member and issue voucher' do
       @marketing_rule = create(:register_rule, :valid, merchant_store: @store)
       @voucher_meta = create(:active_voucher_meta)
       @post_action = create(:voucher_action, voucher_meta: @voucher_meta, marketing_rule: @marketing_rule)
       post '/engine/pos/members', {merchant_num: @store.merchant_number, mobile: '13981842941', bank_card: '6225751111111111111'}.merge(platform_account_key_secret)
       response.status.should be == 200
       body = JSON.parse(response.body)
       body['receipt']['transaction_type'].should be == MessageProperties::TRAN_TYPE_NEW_MEMBER
       body['receipt']['footer_m'].should_not be_nil
       body['receipt']['extra_rows_m'].should_not be_nil
       body['receipt']['extra_rows'].should_not be_nil
       body['receipt']['footer_m'].should_not be_nil

       credit_account = Member::IndividualCreditAccount.where(mobile: '13981842941').first
       credit_account.status.should be == Member::CreditAccount::INACTIVATED
       credit_account.should_not be_nil
       credit_account.bank_cards.count.should be == 1
       credit_account.bank_cards.first.card_num.should be == '6225751111111111111'
       credit_account.bank_cards.first.card_type.should be == Member::BankCard::CREDIT_CARD
       credit_account.bank_cards.first.bank_name.should be == '中国招商银行'
       credit_account.referer_account.id.should be == @store_account.id

       credit_account.vouchers.size.should be == 1
       credit_account.vouchers.first.aliases.should be == @voucher_meta.aliases
       voucher_log = Trade::VoucherTransactionLog.where(transaction_type: Trade::VoucherTransactionLog::ISSUE).first
       voucher_log.should_not be_nil
       voucher_log.primary_transaction_ref_id.should be_nil
       voucher_log.transaction_datetime.should_not be_nil
       voucher_log.issue_event.should be == Trade::VoucherTransactionLog::SYSTEM
       voucher_log.merchant_num.should be == @store.merchant_number
       voucher_log.merchant_name.should be == @store.name
       voucher_log.merchant_store_id.should be == @store.id
       voucher_log.voucher_meta_code.should be == @voucher_meta.code
     end

     it 'should not register new user if mobile is taken' do
       Member::IndividualCreditAccount.create!(mobile: '1234')
       post '/engine/pos/members', {merchant_num: @store.merchant_number, mobile: '1234', bank_card: '4321111111111111111111'}.merge(platform_account_key_secret)
       response.status.should be == 419
       body = JSON.parse(response.body)
       body['screen_msg'].should be == MessageProperties::MEMBER_EXISTS
     end

     it 'should not register new user if bank_card is taken' do
       Member::BankCard.create!(card_num: '4321111111111111111111', card_type: Member::BankCard::DEBIT_CARD)
       post '/engine/pos/members', {merchant_num: @store.merchant_number, mobile: '13981842941', bank_card: '4321111111111111111111'}.merge(platform_account_key_secret)
       response.status.should be == 419
       body = JSON.parse(response.body)
       body['screen_msg'].should be == MessageProperties::BANK_CARD_EXISTS
       Member::IndividualCreditAccount.where(mobile: '13981842941').count.should be == 0
     end

     it 'should not register new user if bank_card num is too short' do
       post '/engine/pos/members', {merchant_num: @store.merchant_number, mobile: '13981842941', bank_card: '432111111'}.merge(platform_account_key_secret)
       response.status.should be == 419
       body = JSON.parse(response.body)
       body['screen_msg'].should be == MessageProperties::WRONG_BANK_CARD_NUM
       Member::IndividualCreditAccount.where(mobile: '13981842941').count.should be == 0
     end
  end

  describe 'bind new card' do
    before :each do
      @account = Member::IndividualCreditAccount.create!(mobile: '13981842941')
    end
    it 'should bind new card if bank_card is missing' do
      put '/engine/pos/members', {merchant_num: @store.merchant_number, mobile: '1111'}.merge(platform_account_key_secret)
      response.status.should be == 400
    end

    it 'should not bind new card if mobile is missing' do
      put '/engine/pos/members', {merchant_num: @store.merchant_number, bank_card: '6225751111111111111'}.merge(platform_account_key_secret)
      response.status.should be == 400
    end
    it 'should bind new card' do
      SmsWorker.any_instance.should_receive(:perform).with(@account.mobile, '尊敬的爱刷会员，您已成功绑定尾号为1111的银行卡, 您可以使用该银行卡立享爱刷超值服务。www.aishua.cn【爱刷】', 100)
      put '/engine/pos/members', {merchant_num: @store.merchant_number, mobile: @account.mobile, bank_card: '6225751111111111111'}.merge(platform_account_key_secret)
      response.status.should be == 200
      body = JSON.parse(response.body)
      body['receipt']['transaction_type'].should be == MessageProperties::TRAN_TYPE_NEW_CARD
      body['receipt']['footer_m'].should_not be_nil
      body['receipt']['extra_rows_m'].should_not be_nil
      body['receipt']['extra_rows'].should_not be_nil
      body['receipt']['footer_m'].should_not be_nil
      @account.bank_cards.count.should be == 1
      @account.bank_cards.first.card_num.should be == '6225751111111111111'
      @account.bank_cards.first.card_type.should be == Member::BankCard::CREDIT_CARD
      @account.bank_cards.first.bank_name.should be == '中国招商银行'
      @account.merchant_stores.size.should be == 1
      @account.merchant_stores.first.should be == @store
    end

    it 'should bind 2 cards' do
      put '/engine/pos/members', {merchant_num: @store.merchant_number, mobile: @account.mobile, bank_card: '6225751111111111111'}.merge(platform_account_key_secret)
      response.status.should be == 200
      put '/engine/pos/members', {merchant_num: @store.merchant_number, mobile: @account.mobile, bank_card: '6225751111111111112'}.merge(platform_account_key_secret)
      response.status.should be == 200
      @account.bank_cards.count.should be == 2
      @account.merchant_stores.size.should be == 1
      @account.merchant_stores.first.should be == @store
    end

    it 'should bind new card and issue voucher' do
      @marketing_rule = create(:bind_card_rule, :valid, merchant_store: @store)
      @voucher_meta = create(:active_voucher_meta)
      @post_action = create(:voucher_action, voucher_meta: @voucher_meta, marketing_rule: @marketing_rule)
      put '/engine/pos/members', {merchant_num: @store.merchant_number, mobile: @account.mobile, bank_card: '6225751111111111111'}.merge(platform_account_key_secret)
      response.status.should be == 200
      body = JSON.parse(response.body)
      body['receipt']['transaction_type'].should be == MessageProperties::TRAN_TYPE_NEW_CARD
      body['receipt']['footer_m'].should_not be_nil
      body['receipt']['extra_rows_m'].should_not be_nil
      body['receipt']['extra_rows'].should_not be_nil
      body['receipt']['footer_m'].should_not be_nil
      @account.bank_cards.count.should be == 1
      @account.bank_cards.first.card_num.should be == '6225751111111111111'
      @account.bank_cards.first.card_type.should be == Member::BankCard::CREDIT_CARD
      @account.bank_cards.first.bank_name.should be == '中国招商银行'

      @account.vouchers.size.should be == 1
      @account.vouchers.first.aliases.should be == @voucher_meta.aliases
      voucher_log = Trade::VoucherTransactionLog.where(transaction_type: Trade::VoucherTransactionLog::ISSUE).first
      voucher_log.should_not be_nil
      voucher_log.primary_transaction_ref_id.should be_nil
      voucher_log.transaction_datetime.should_not be_nil
      voucher_log.issue_event.should be == Trade::VoucherTransactionLog::SYSTEM
      voucher_log.merchant_num.should be == @store.merchant_number
      voucher_log.merchant_name.should be == @store.name
      voucher_log.merchant_store_id.should be == @store.id
      voucher_log.voucher_meta_code.should be == @voucher_meta.code
    end

    it 'should bind new card for unknown bank' do
      put '/engine/pos/members', {merchant_num: @store.merchant_number, mobile: @account.mobile, bank_card: '1234567890123456'}.merge(platform_account_key_secret)
      response.status.should be == 200
      body = JSON.parse(response.body)
      body['receipt']['transaction_type'].should be == MessageProperties::TRAN_TYPE_NEW_CARD
      body['receipt']['footer_m'].should_not be_nil
      body['receipt']['extra_rows_m'].should_not be_nil
      body['receipt']['extra_rows'].should_not be_nil
      body['receipt']['footer_m'].should_not be_nil
      @account.bank_cards.count.should be == 1
      @account.bank_cards.first.card_num.should be == '1234567890123456'
      @account.bank_cards.first.card_type.should be == Member::BankCard::DEBIT_CARD
      @account.bank_cards.first.bank_name.should be_nil
    end

    it 'should not bind new card if member not registered' do
      put '/engine/pos/members', {merchant_num: @store.merchant_number, mobile: '13981842940', bank_card: '4321111111111111111111'}.merge(platform_account_key_secret)
      response.status.should be == 419
      body = JSON.parse(response.body)
      body['screen_msg'].should be == MessageProperties::NOT_MEMBER
    end

    it 'should not bind new card mobile is not valid' do
      put '/engine/pos/members', {merchant_num: @store.merchant_number, mobile: '1', bank_card: '4321111111111111111111'}.merge(platform_account_key_secret)
      response.status.should be == 419
      body = JSON.parse(response.body)
      body['screen_msg'].should be == MessageProperties::INVALID_MOBILE
      Member::BankCard.count.should be == 0
    end

    it 'should not bind new card if max card number exceeds' do
      Member::IndividualCreditAccount::MAX_BIND_CARD_NUM.times do |i|
        @account.add_bank_card("111111111111111111111#{i}", Member::BankCard::DEBIT_CARD)
      end
      put '/engine/pos/members', {merchant_num: @store.merchant_number, mobile: @account.mobile, bank_card: '4321111111111111111111'}.merge(platform_account_key_secret)
      response.status.should be == 419
      body = JSON.parse(response.body)
      body['screen_msg'].should be == MessageProperties::BANK_CARD_EXCEEDS_LIMIT
    end

    it 'should not bind new card if bank_card num is too short' do
      put '/engine/pos/members', {merchant_num: @store.merchant_number, mobile: @account.mobile, bank_card: '432111'}.merge(platform_account_key_secret)
      response.status.should be == 419
      body = JSON.parse(response.body)
      body['screen_msg'].should be == MessageProperties::WRONG_BANK_CARD_NUM
    end
  end

  describe 'query member card' do
    before :each do
      @account = Member::IndividualCreditAccount.create!(mobile: '112233455')
      @account.add_bank_card('4321111111111111111111', Member::BankCard::DEBIT_CARD)
    end

    it 'should return query result for member card' do
      get '/engine/pos/members', {merchant_num: @store.merchant_number, bank_card: '4321111111111111111111'}.merge(platform_account_key_secret)
      response.status.should be == 200
      body = JSON.parse(response.body)
      body['screen_msg'].should be == MessageProperties::IS_MEMBER_CARD
    end

    it 'should return query result for none member card' do
      get '/engine/pos/members', {merchant_num: @store.merchant_number, bank_card: '1111111111'}.merge(platform_account_key_secret)
      response.status.should be == 200
      body = JSON.parse(response.body)
      body['screen_msg'].should be == MessageProperties::IS_NOT_MEMBER_CARD
    end

    it 'should return error missing bank_card parameter' do
      get '/engine/pos/members', {merchant_num: @store.merchant_number}.merge(platform_account_key_secret)
      response.status.should be == 400
    end
  end
end
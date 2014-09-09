require 'spec_helper'

describe Engine::POS::TransactionsAPI do
  before :each do
    @store = create(:merchant_store, :active)
    @credit_account = create(:individual_credit_account, mobile: '13981842941', name: 'testxx', bank_card: '1234567812345678')
    @bank_card = @credit_account.bank_cards.first
  end

  describe 'error cases' do
    before :each do
      @payment_plan = create(:credit_back, customer_rate: 0.1, merchant_rate: 0.15, referer_rate: 0.03, merchant_store: @store)
    end
    it 'should not create transaction if store is not valid' do
      post '/engine/pos/transactions', {merchant_num: 'none_existing_one', money_amount: 1000, plan_type: 'credit_back'}.merge(platform_account_key_secret)
      response.status.should be == 419
      body = JSON.parse(response.body)
      body['screen_msg'].should be == MessageProperties::MERCHANT_NOT_SUPPORTED
    end


    it 'should not finish transaction if trans_id is not valid' do
      put "/engine/pos/transactions/#{99999}", {status: 1,
                                         transaction_datetime: '2013-07-18 15:47:35',
                                         sequence_num: '111',
                                         terminal_num: '222',
                                         merchant_amount: 850
      }.merge(platform_account_key_secret)
      response.status.should be == 419
    end

    it 'should not create transaction if no payment plan is available' do
      Pay::PaymentPlan.destroy_all
      post '/engine/pos/transactions', {bank_card: @bank_card.card_num, merchant_num: @store.merchant_number, money_amount: 1000, plan_type: 'credit_back'}.merge(platform_account_key_secret)
      response.status.should be == 419
      body = JSON.parse(response.body)
      body['screen_msg'].should be == MessageProperties::MERCHANT_NOT_SUPPORTED
    end

    it 'should not create transaction if no payment plan is valid' do
      @payment_plan.disable
      post '/engine/pos/transactions', {bank_card: @bank_card.card_num, merchant_num: @store.merchant_number, money_amount: 1000, plan_type: 'credit_back'}.merge(platform_account_key_secret)
      response.status.should be == 419
      body = JSON.parse(response.body)
      body['screen_msg'].should be == MessageProperties::MERCHANT_NOT_SUPPORTED
    end

    it 'should not create transaction if no payment plan is in valid time span' do
      @payment_plan.update_attributes(valid_till: 1.minute.ago)
      post '/engine/pos/transactions', {bank_card: @bank_card.card_num, merchant_num: @store.merchant_number, money_amount: 1000, plan_type: 'credit_back'}.merge(platform_account_key_secret)
      response.status.should be == 419
      body = JSON.parse(response.body)
      body['screen_msg'].should be == MessageProperties::MERCHANT_NOT_SUPPORTED
    end

  end
end
require 'spec_helper'

describe Engine::POS::CreditsAPI do
  before :each do
    @store = create(:merchant_store, :active)
    @account = create(:individual_credit_account, mobile: '112233455', bank_card: '4321111111111111111111')

  end

  it 'should return correct credit' do
    @account.apply_consumption_credit!(1000, '4321111111111111111111')
    get '/engine/pos/credits', {merchant_num: @store.merchant_number, bank_card: '4321111111111111111111'}.merge(platform_account_key_secret)
    response.status.should be == 200
    body = JSON.parse(response.body)
    body['screen_msg'].include?('1000').should be_true
  end

  it 'should not return correct credit if bank_card is missing' do
    @account.apply_consumption_credit!(1000, '4321111111111111111111')
    get '/engine/pos/credits', {merchant_num: @store.merchant_number}.merge(platform_account_key_secret)
    response.status.should be == 400
  end

  it 'should not return credit for non member' do
    get '/engine/pos/credits', {merchant_num: @store.merchant_number, bank_card: '111111111111'}.merge(platform_account_key_secret)
    response.status.should be == 419
    body = JSON.parse(response.body)
    body['screen_msg'].should be == MessageProperties::NOT_MEMBER
  end
end
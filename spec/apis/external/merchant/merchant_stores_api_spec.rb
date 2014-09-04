#encoding:utf-8
require 'spec_helper'

describe External::Merchant::MerchantStoresAPI do

  before :each do
    @store = create(:merchant_store)
    @merchant_credit_account = @store.credit_account
  end

  it 'find merchant store by merchant number' do
    get '/external/merchant_stores', query: {merchant_number_eq: @store.merchant_number}
    response.status.should be == 200
    body = JSON.parse(response.body)
    body['total'].should be == 1
    records = body['records']
    records.size.should be == 1
    records[0]['name'].should be == @store.name
  end

  it 'find merchant store by external id' do
    get '/external/merchant_stores', query: {credit_account_external_id_eq: @merchant_credit_account.external_id}
    response.status.should be == 200
    body = JSON.parse(response.body)
    body['total'].should be == 1
    records = body['records']
    records.size.should be == 1
    records[0]['name'].should be == @store.name
  end

  describe 'check transaction' do
    before :each do
      @tl = Trade::TransactionLog.new
      @tl.log_type = Trade::TransactionLog::PRIMARY
      @tl.transaction_type = Trade::TransactionLog::CREDIT_BACK
      @tl.transaction_datetime = Time.now
      @tl.media_num = '123456'
      @tl.status = Trade::TransactionLog::NORMAL
      @tl.merchant_store_id = @store.id
      @tl.save!
      @tl = Trade::TransactionLog.first!
    end

    it 'should check transaction' do
      expect {
        put "/external/merchant_stores/#{@store.id}/transaction_logs/#{@tl.id[0]}", data: {checked: Trade::TransactionLog::CHECKED}
        response.status.should eq (200)
        body = JSON.parse response.body
        body['success'].should be == 'success'
      }.to change{@tl.reload.checked}.from(Trade::TransactionLog::NOT_CHECKED).to(Trade::TransactionLog::CHECKED)
      expect {
        put "/external/merchant_stores/#{@store.id}/transaction_logs/#{@tl.id[0]}", data: {checked: Trade::TransactionLog::NOT_CHECKED}
        response.status.should eq (200)
        body = JSON.parse response.body
        body['success'].should be == 'success'
      }.to change{@tl.reload.checked}.from(Trade::TransactionLog::CHECKED).to(Trade::TransactionLog::NOT_CHECKED)
    end
  end

end
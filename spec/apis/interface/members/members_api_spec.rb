#encoding:utf-8
require 'spec_helper'

describe External::Member::MembersAPI do

  describe 'individual credit account' do
    before(:each) do
      @credit_account = create(:individual_credit_account, mobile: '13981842940')
    end

    it "get user's credit accounts by mobile" do
      get '/external/members', query: {mobile_eq: @credit_account.mobile}
      response.status.should be == 200
      body = JSON.parse(response.body)
      body['total'].should be == 1
      records = body['records']
      records.size.should be == 1
      records[0]['name'].should be == @credit_account.name
      records[0]['mobile'].should be == @credit_account.mobile
      records[0]['address'].should be == @credit_account.address
    end

    it 'get user credit accounts by external_id' do
      get '/external/members', query: {external_id_eq: @credit_account.external_id}
      response.should be_ok
      body = JSON.parse(response.body)
      body['total'].should be == 1
      records = body['records']
      records.size.should be == 1
      records[0]['name'].should be == @credit_account.name
      records[0]['mobile'].should be == @credit_account.mobile
      records[0]['address'].should be == @credit_account.address
    end

    it "should not get user's credit accounts by not exist external_id" do
      get '/external/members', query: {external_id_eq: 'none'}
      response.status.should be == 200
      body = JSON.parse(response.body)
      body['total'].should be == 0
      body['records'].size.should be == 0
    end

    it "should not get user's credit accounts by not exist mobile" do
      get '/external/members', query: {mobile_eq: 'none'}
      response.status.should be == 200
      body = JSON.parse(response.body)
      body['total'].should be == 0
      body['records'].size.should be == 0
    end

    it 'should create an active credit account' do
      mobile = '18688888881'
      post '/external/members', data: {mobile: mobile}
      response.status.should be == 200
      new_account = Member::CreditAccount.where(mobile: mobile).first
      new_account.should_not be_nil
      new_account.mobile.should be == mobile
      new_account.status.should be == Member::CreditAccount::ACTIVATED
    end

    it 'should create a inactive credit account' do
      mobile = '18688888881'
      post '/external/members', data: {mobile: mobile, status: Member::CreditAccount::INACTIVATED}
      response.status.should be == 200
      new_account = Member::CreditAccount.where(mobile: mobile).first
      new_account.should_not be_nil
      new_account.mobile.should be == mobile
      new_account.status.should be == Member::CreditAccount::INACTIVATED
    end

    it 'create a credit account with referer' do
      mobile = '18688888881'
      post '/external/members', data: {mobile: mobile, referer_external_id: @credit_account.external_id}
      response.status.should be == 200

      new_account = Member::CreditAccount.find_by_mobile(mobile)
      new_account.should_not be_nil
      new_account.referer_account_id.should be == @credit_account.id
      body = JSON.parse(response.body)
      body['external_id'].should be == new_account.external_id
    end

    it 'should not create credit account when mobile has been taken' do
      mobile = @credit_account.mobile
      expect { post '/external/members', data: {mobile: mobile} }.to_not change { Member::CreditAccount.where(mobile: mobile).size }
      response.status.should be == 419
      body = JSON.parse(response.body)
      body['error'].should be == 'MOBILE_HAS_BEEN_TAKEN'
    end

    it 'should not create credit account if mobile is wrong' do
      mobile = '110'
      expect {post '/external/members', data: {mobile: mobile}}.to_not change{Member::CreditAccount.where(mobile: mobile).size}
      response.status.should be == 419
      body = JSON.parse(response.body)
      body['error'].should be == 'INVALID_MOBILE'
    end

    it 'should update credit account' do
      mobile = '18611111111'
      name = 'new name'
      address = 'new address'
      put "/external/members/#{@credit_account.external_id}", data: {:mobile => mobile, :name => name, :address => address, status: Member::CreditAccount::ACTIVATED}
      response.status.should be == 200
      @credit_account.reload
      @credit_account.mobile.should be == mobile
      @credit_account.name.should be == name
      @credit_account.address.should be == address
      @credit_account.status.should be == Member::CreditAccount::ACTIVATED
    end

    it 'should not update credit account when credit account can not be found' do
      put '/external/members/not_found', data: {:mobile => '13981842999'}
      response.status.should be == 404
    end

    it 'should not update mobile when mobile has been taken' do
      mobile = '18611111111'
      create(:individual_credit_account, mobile: mobile)
      expect{put "/external/members/#{@credit_account.external_id}", data: {:mobile => mobile}}.to_not change{@credit_account.reload.mobile}
      response.status.should be == 419
      body = JSON.parse(response.body)
      body['error'].should be == 'MOBILE_HAS_BEEN_TAKEN'
    end

    it 'should find credit accounts by referer' do
      referee = create(:individual_credit_account, referer_account: @credit_account)
      get '/external/members/', query: {referer_account_external_id_eq: @credit_account.external_id}
      response.status.should be == 200
      body = JSON.parse(response.body)
      body['total'].should be == 1
      body['records'][0]['external_id'].should be == referee.external_id
    end

    describe 'merchant membership' do
      before :each do
        @store = create(:merchant_store)
        @referer_account = @store.credit_account
      end

      it 'it should becomes member of the store' do
        mobile = '18688888881'
        post '/external/members', data: {:mobile => mobile, :referer_external_id => @referer_account.external_id}
        response.should be_ok

        new_account = Member::CreditAccount.find_by_mobile(mobile)
        new_account.should_not be_nil
        new_account.referer_account_id.should be == @referer_account.id
        body = JSON.parse(response.body)
        body['external_id'].should be == new_account.external_id
        new_account.merchant_stores.size.should be == 1
        new_account.merchant_stores.first.should be == @store
        @store.member_accounts.count.should be == 1
        @store.member_accounts.first.should be == new_account
      end
    end
  end

  describe 'merchant credit account' do
    before :each do
      @store = create(:merchant_store)
      @merchant_credit_account = @store.credit_account
    end
    it 'should find merchant credit account' do
      get '/external/members', query: {merchant_store_merchant_number_eq: @store.merchant_number}
      response.status.should be == 200
      body = JSON.parse(response.body)
      body['total'].should be == 1
      records = body['records']
      records.size.should be == 1
      records[0]['name'].should be == @merchant_credit_account.name
      records[0]['mobile'].should be == @merchant_credit_account.mobile
      records[0]['address'].should be == @merchant_credit_account.address
    end

    it 'should not find merchant if merchant num is wrong' do
      get '/external/members', query: {merchant_store_merchant_number_eq: 'not'}
      response.status.should be == 200
      body = JSON.parse(response.body)
      body['total'].should be == 0
      body['records'].size.should be == 0
    end
  end
end
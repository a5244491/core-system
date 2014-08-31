require 'spec_helper'

describe Merchant::MerchantStoresController do
  render_views
  before(:each) do
    create_and_login_user('test', Users::SystemUser::DEPT_MANAGER)
    request.env['HTTP_REFERER'] = 'http://test.com'
  end

  describe 'index action' do
    it 'render index template and response 200' do
      get :index
      response.code.should eq('200')
      response.should render_template('merchant/merchant_stores/index')
    end
  end

  describe 'create action' do
    it 'should create merchant store' do
      merchant_store = {
          :name => '111',
          :merchant_number => '111',
          :standard_rate => 1.1
      }
      post :create, :merchant_merchant_store => merchant_store
      response.code.should eq('302')
      flash[:error].should be_nil
      flash[:success].should_not be_nil
      ms = Merchant::MerchantStore.where(name: merchant_store[:name]).first
      ms.should_not be_nil
      ms.merchant_number.should be == merchant_store[:merchant_number]
      ms.standard_rate.should be == merchant_store[:standard_rate]
    end

    it 'should not create merchant store when required field is blank' do
      merchant_store = {
          :name => '111',
          :standard_rate => 1.1
      }
      expect { post :create, :merchant_merchant_store => merchant_store }.to raise_error ActionController::ParameterMissing
      Merchant::MerchantStore.where(name: merchant_store[:name]).first.should be_nil
    end

  end

  describe 'destroy action' do
    it 'should destroy merchant store' do
      merchant_store = create(:merchant_store)
      delete :destroy, :id => merchant_store.id
      response.code.should eq('302')
      flash[:error].should be_nil
      flash[:success].should_not be_nil
      Merchant::MerchantStore.where(id: merchant_store.id).first.should be_nil
    end

    it 'should not destroy merchant store when merchant store is not in editing status' do
      merchant_store = create(:merchant_store, status: :active)
      delete :destroy, :id => merchant_store.id
      response.code.should eq('302')
      flash[:error].should be == Tips::MERCHANT_CAN_NOT_DELETE
      flash[:success].should be_nil
      Merchant::MerchantStore.where(id: merchant_store.id).first.should_not be_nil
    end
  end

  describe 'update action' do
    before :each do
      @merchant_store = create(:merchant_store)
    end
    it 'should edit merchant store' do
      update = {
          :name => 'new name',
          :merchant_number => '222',
          :standard_rate => 2.2
      }
      put :update, :id => @merchant_store.id, :merchant_merchant_store => update
      response.code.should eq('302')
      flash[:error].should be_nil
      flash[:success].should_not be_nil
      ms = Merchant::MerchantStore.find(@merchant_store.id)
      ms.name.should be == update[:name]
      ms.merchant_number.should be == update[:merchant_number]
      ms.standard_rate.should be == update[:standard_rate]
      ms.credit_account.name.should be == update[:name]
    end

    it 'should not edit merchant store when required field is blank' do
      update = {
          :name => 'new name',
          :standard_rate => 2.2
      }
      expect { put :update, :id => @merchant_store.id, :merchant_merchant_store => update }.to raise_error ActionController::ParameterMissing
    end

    it 'should not edit merchant store when merchant status is not editing' do
      @merchant_store.submit_audit!
      update = {
          :name => 'new name',
          :standard_rate => 2.2,
          :merchant_number => 123
      }
      put :update, :id => @merchant_store.id, :merchant_merchant_store => update
      response.code.should eq('200')
      response.should render_template('edit')
      flash[:error].should_not be_nil
      flash[:success].should be_nil
      ms = Merchant::MerchantStore.find(@merchant_store.id)
      ms.name.should be == @merchant_store.name
      ms.standard_rate.should be == @merchant_store.standard_rate
    end
  end

  describe 'update merchant store status' do
    before(:each) do
      @merchant_store = create(:merchant_store)
      @request.env['HTTP_REFERER'] = 'http://test.com'
    end

    it 'should submit audit merchant store' do
      post :submit_audit, :merchant_store_id => @merchant_store.id
      response.code.should eq('302')
      flash[:error].should be_nil
      flash[:success].should be == '审核成功'
      ms = Merchant::MerchantStore.find(@merchant_store.id)
      ms.auditing?.should be_true
    end

    it 'should not submit audit merchant store when store status is auditing' do
      @merchant_store.submit_audit!
      post :submit_audit, :merchant_store_id => @merchant_store.id
      response.code.should eq('302')
      flash[:error].should_not be_nil
      flash[:success].should be_nil
    end

    it 'should reject audit merchant store' do
      @merchant_store.submit_audit!
      post :reject_audit, :merchant_store_id => @merchant_store.id
      response.code.should eq('302')
      flash[:error].should be_nil
      flash[:success].should be == '审核成功'
      ms = Merchant::MerchantStore.find(@merchant_store.id)
      ms.editing?.should be_true
    end


    it 'should approve audit merchant store' do
      @merchant_store.submit_audit!
      post :approve_audit, :merchant_store_id => @merchant_store.id
      response.code.should eq('302')
      flash[:error].should be_nil
      flash[:success].should be == '审核成功'
      ms = Merchant::MerchantStore.find(@merchant_store.id)
      ms.audit_passed?.should be_true
    end

    it 'should active merchant store' do
      @merchant_store.submit_audit!
      @merchant_store.approve_audit!
      post :enable, :merchant_store_id => @merchant_store.id
      response.code.should eq('302')
      flash[:error].should be_nil
      flash[:success].should be == '审核成功'
      ms = Merchant::MerchantStore.find(@merchant_store.id)
      ms.active?.should be_true
    end

    it 'should inactive merchant store' do
      @merchant_store.submit_audit!
      @merchant_store.approve_audit!
      @merchant_store.enable!
      post :disable, :merchant_store_id => @merchant_store.id
      response.code.should eq('302')
      flash[:error].should be_nil
      flash[:success].should be == '审核成功'
      ms = Merchant::MerchantStore.find(@merchant_store.id)
      ms.audit_passed?.should be_true
    end
  end

end

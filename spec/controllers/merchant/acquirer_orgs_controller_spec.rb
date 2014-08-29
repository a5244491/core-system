require 'spec_helper'

describe Merchant::AcquirerOrgsController do
  before(:each) do
    create_and_login_user('test', Users::SystemUser::DEPT_MANAGER)
  end
  render_views

  describe 'index action' do
    it 'render index template and response 200' do
      get :index
      response.code.should eq('200')
      response.should render_template('index')
    end
  end

  describe 'create action' do
    it 'should create acquirer organization' do
      post :create, merchant_acquirer_org: {acquirer_name: '112', acquirer_code: '123'}
      response.code.should eq('302')
      acquirer_org = Merchant::AcquirerOrg.first
      acquirer_org.acquirer_name.should eq '112'
      acquirer_org.acquirer_code.should eq '123'
    end
  end

  describe 'update action' do
    before :each do
      @acquirer_org = Merchant::AcquirerOrg.create!(acquirer_name: '12', acquirer_code: '13')
    end
    it 'should update acquirer organization' do
      put :update, id: @acquirer_org.id, merchant_acquirer_org: {acquirer_name: '112', acquirer_code: '123'}
      response.code.should eq('302')
      acquirer_org = Merchant::AcquirerOrg.first
      acquirer_org.acquirer_name.should eq '112'
      acquirer_org.acquirer_code.should eq '123'
    end
  end

  describe 'destroy action' do
    before :each do
      @acquirer_org = Merchant::AcquirerOrg.create!(acquirer_name: '12', acquirer_code: '13')
    end

    it 'should destroy acquirer organization' do
      delete :destroy, id: @acquirer_org.id
      response.code.should eq('302')
      Merchant::AcquirerOrg.where(id: @acquirer_org.id).first.should be_nil
    end
  end
end

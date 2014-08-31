require 'spec_helper'

describe System::PlatformAccountsController do
  before :each do
    create_and_login_user('test')
    @platform_account = System::PlatformAccount.new
    @platform_account.account_name = 'aaa'
    @platform_account.access_target = System::PlatformAccount::CORE_ENGINE
    @platform_account.status = System::PlatformAccount::ACTIVE
    @platform_account.remark = 'aaa'
    @platform_account.save!
  end

  describe 'index action' do
    it 'should render index template and response 200' do
      get :index
      response.code.should eq('200')
      response.should render_template('index')
    end
  end

  describe 'new action' do
    it 'should render new template and response 200' do
      get :new
      response.code.should eq('200')
      response.should render_template('new')
    end
  end

  describe 'create action' do
    it 'should create account' do
      post :create, system_platform_account: {account_name: 'bbb', status: System::PlatformAccount::ACTIVE, access_target: System::PlatformAccount::CORE_ENGINE, remark: 'bbb'}
      response.code.should eq('302')
      flash[:success].should_not be_nil
      user = System::PlatformAccount.where(account_name: 'bbb').first
      user.account_name.should be == 'bbb'
      user.remark.should be == 'bbb'
      user.status.should be == System::PlatformAccount::ACTIVE
      user.access_target.should be == System::PlatformAccount::CORE_ENGINE
    end
  end

  describe 'update action' do
    it 'should update account' do
      put :update, id: @platform_account.id, system_platform_account: {account_name: 'ccc', status: System::PlatformAccount::INACTIVE, access_target: System::PlatformAccount::CORE_INTERFACE, remark: 'ccc'}
      response.code.should eq('302')
      flash[:success].should_not be_nil
      account = System::PlatformAccount.find(@platform_account.id)
      account.id.should == @platform_account.id
      account.account_name.should be == 'ccc'
      account.remark.should be == 'ccc'
      account.status.should be == System::PlatformAccount::INACTIVE
      account.access_target.should be == System::PlatformAccount::CORE_INTERFACE
    end
  end

  describe 'edit action' do
    it 'should render edit template and response 200' do
      get :edit, id: @platform_account.id
      response.code.should eq('200')
      response.should render_template('edit')
    end
  end

  describe 'destroy action' do
    it 'should destroy account' do
      delete :destroy, id: @platform_account.id
      response.code.should eq('302')
      flash[:success].should_not be_nil
      System::PlatformAccount.where(id: @platform_account.id).first.should be_nil
    end
  end
end

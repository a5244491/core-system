require 'spec_helper'

describe Users::SystemUsersController do
  before(:each) do
    @admin = create_and_login_user('admin_test')
    @system_user = create(:system_user)
    request.env['HTTP_REFERER'] = 'http://test.com'
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
    it 'should create system user' do
      post :create, users_system_user: {name: 'bbb', role_name: Users::SystemUser::SALES_ASSIST, real_name: 'bbb', password: 'bbb', password_confirmation: 'bbb'}
      response.code.should eq('302')
      flash[:success].should_not be_nil
      user = Users::SystemUser.where('name = ?', 'bbb').first
      user.name.should be == 'bbb'
      user.real_name.should be == 'bbb'
      user.role_name.should be == Users::SystemUser::SALES_ASSIST
    end

    it 'should not create system user if name is taken' do
      post :create, users_system_user: {name: @system_user.name, role_name: Users::SystemUser::SALES_ASSIST, real_name: 'bbb', password: 'bbb', password_confirmation: 'bbb'}
      response.code.should eq('200')
      response.should render_template('new')
      flash[:error].should_not be_nil
      Users::SystemUser.where(name: @system_user.name).count.should be == 1
    end

    it 'should not create admin user' do
      post :create, users_system_user: {name: 'bbb', role_name: Users::SystemUser::ADMIN, real_name: 'bbb', password: 'bbb', password_confirmation: 'bbb'}
      response.code.should eq('200')
      response.should render_template('new')
      flash[:error].should_not be_nil
      Users::SystemUser.where(name: @system_user.name).count.should be == 1
    end
  end

  describe 'edit action' do
    it 'render edit template and response 200' do
      get :edit, id: @system_user.id
      response.code.should eq('200')
      response.should render_template('edit')
    end
  end

  describe 'update action' do
    it 'should update system user' do
      put :update, id: @system_user.id, users_system_user: {name: 'ccc', role_name: Users::SystemUser::SALES_ASSIST, real_name: 'ccc'}
      response.code.should eq('302')
      flash[:success].should_not be_nil
      user = Users::SystemUser.where('id = ?', @system_user.id).first
      user.id.should be == @system_user.id
      user.name.should be == 'ccc'
      user.real_name.should be == 'ccc'
      user.role_name.should be == Users::SystemUser::SALES_ASSIST
    end

    it 'should not update admin user' do
      put :update, id: @admin.id, users_system_user: {name: 'ccc', role_name: Users::SystemUser::SALES_ASSIST, real_name: 'ccc'}
      response.code.should eq('200')
      response.should render_template('edit')
      flash[:error].should_not be_nil
      @admin.reload.role_name.should be == Users::SystemUser::ADMIN
    end
  end

  describe 'destroy action' do
    it 'should destroy system user' do
      get :destroy, id: @system_user.id
      response.code.should eq('302')
      flash[:success].should_not be_nil
      Users::SystemUser.where(id: @system_user.id).first.should be_nil
    end

    it 'should not destroy admin' do
      get :destroy, id: @admin.id
      response.code.should eq('302')
      flash[:error].should_not be_nil
      Users::SystemUser.where(id: @admin.id).first.should_not be_nil
    end
  end
end

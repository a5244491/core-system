require 'spec_helper'

describe SessionsController do
  render_views

  before :each do
    @image_captcha = '1111'
    session[:captcha] = @image_captcha
    @system_user = create(:system_user)
  end

  it 'render sessions new template and response 200' do
    get :new
    response.code.should eq('200')
    response.should render_template('sessions/new')
  end

  it 'should login success' do
    post :create, :username => @system_user.name, :password => @system_user.password, image_captcha: @image_captcha
    response.code.should eq('302')
    session[:user].should_not be_nil
  end

  it 'should login failed' do

    post :create, :username => @system_user.name, :password => 'wrong wrong'
    response.code.should eq('302')
    session[:user].should be_nil
    flash[:error].should == '验证码错误'
  end

  it 'should logout' do
    login(@system_user.name, @system_user.password)
    get :destroy
    response.code.should eq('302')
    session[:user].should be_nil
  end
end

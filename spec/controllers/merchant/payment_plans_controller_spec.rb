require 'spec_helper'

describe Merchant::PaymentPlansController do
  render_views
  before(:each) do
    @merchant_store = create(:merchant_store)
    create_and_login_user('test', Users::SystemUser::DEPT_MANAGER)
    request.env['HTTP_REFERER'] = 'http://test.com'
  end

  describe 'index action' do
    it 'render index template and response 200' do
      get :index, :merchant_store_id => @merchant_store.id
      response.code.should eq('200')
      response.should render_template('index')
    end
  end

  describe 'enable action' do
    before :each do
      @payment_plan = @merchant_store.payment_plans.first
      @payment_plan.disable
    end

    it 'should enable payment plan' do
      patch :enable, merchant_store_id: @merchant_store.id, payment_plan_id: @payment_plan.id
      response.code.should eq('302')
      flash[:error].should be_nil
      flash[:success].should_not be_nil
      p = Pay::PaymentPlan.find(@payment_plan.id)
      p.status.should == Pay::PaymentPlan::VALID
    end
  end
  describe 'disable action' do
    before :each do
      @payment_plan = @merchant_store.payment_plans.first
    end
    it 'should disable payment plan' do
      patch :disable, merchant_store_id: @merchant_store.id, payment_plan_id: @payment_plan.id
      response.code.should eq('302')
      flash[:error].should be_nil
      flash[:success].should_not be_nil
      p = Pay::PaymentPlan.find(@payment_plan.id)
      p.status.should == Pay::PaymentPlan::INVALID
    end
  end

  describe 'destroy action' do
    before :each do
      @payment_plan = create(:bank_discount_rate, :invalid, merchant_store: @merchant_store)
    end
    it 'should payment plan' do
      delete :destroy, :merchant_store_id => @merchant_store.id, :id => @payment_plan.id
      response.code.should eq('302')
      flash[:success].should be == Tips::DELETE_SUCCESS
      flash[:error].should be_nil
      Pay::PaymentPlan.where(id: @payment_plan.id).first.should be_nil
    end

    it 'should not destroy valid plan' do
      @payment_plan.enable
      delete :destroy, :merchant_store_id => @merchant_store.id, :id => @payment_plan.id
      response.code.should eq('302')
      flash[:error].should_not be_nil
      Pay::PaymentPlan.where(id: @payment_plan.id).first.should_not be_nil
    end
  end
end

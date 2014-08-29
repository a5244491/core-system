require 'spec_helper'

describe Merchant::NonePaymentPlansController do
  before :each do
    @merchant_store = create(:merchant_store)
    create_and_login_user('test', Users::SystemUser::DEPT_MANAGER)
  end

  describe 'update action' do
    before :each do
      @payment_plan = create(:none_payment_plan, :invalid, merchant_store: @merchant_store)
    end
    it 'should update payment plan' do
      post_payment_plan = {
          voucher_status: Pay::PaymentPlan::ACCEPT_ALL,
          valid_from: Time.now.strftime(FormFieldsConversion::DATE_TIME_FORMAT),
          valid_till: 10.years.from_now.strftime(FormFieldsConversion::DATE_TIME_FORMAT)
      }

      post :update, :merchant_none_payment_plan => post_payment_plan, :merchant_store_id => @merchant_store.id, :id => @payment_plan.id
      response.code.should eq('302')
      flash[:error].should be_nil
      flash[:success].should_not be_nil
      pp = Pay::NonePaymentPlan.find(@payment_plan.id)
      pp.should_not be_nil
      pp.voucher_status.should be== Pay::PaymentPlan::ACCEPT_ALL
      pp.status.should be == Pay::PaymentPlan::INVALID
    end

    it 'should not update payment plan when payment plan is valid' do
      @payment_plan.enable
      post_payment_plan = {
          voucher_status: Pay::PaymentPlan::ACCEPT_ALL,
          valid_from: Time.now.strftime(FormFieldsConversion::DATE_TIME_FORMAT),
          valid_till: 10.years.from_now.strftime(FormFieldsConversion::DATE_TIME_FORMAT)
      }

      post :update, :merchant_none_payment_plan => post_payment_plan, :merchant_store_id => @merchant_store.id, :id => @payment_plan.id
      response.code.should eq('200')
      response.should render_template('edit')
      flash[:error].should_not be_nil

      pp = Pay::NonePaymentPlan.find(@payment_plan.id)
      pp.should_not be_nil
    end

  end
end

require 'spec_helper'

describe Merchant::BankDiscountsController do
  before :each do
    @merchant_store = create(:merchant_store)
    create_and_login_user('test', Users::SystemUser::DEPT_MANAGER)
  end
  describe 'create action' do
    it 'should create bank_discount plan' do
      bank_name = '中国银行'
      payment_plan = {
          discount_amount_in: 12,
          minimal_money_amount: 20,
          referer_rate: 10,
          discount_rate: 11,
          merchant_rate: 12,
          bank_name: bank_name,
          voucher_status: Pay::PaymentPlan::ACCEPT_ALL,
      }
      post :create, merchant_bank_discount: payment_plan, merchant_store_id: @merchant_store.id
      response.code.should eq('302')
      flash[:error].should be_nil
      flash[:success].should_not be_nil
      pp = Pay::BankDiscount.where(:merchant_store_id => @merchant_store.id).first
      pp.should_not be_nil
      pp.merchant_rate.should be == 0.12
      pp.customer_rate.should be_nil
      pp.referer_rate.should be == 0.1
      pp.discount_rate.should be == 0.11

      pp.bank_name.should be == bank_name
      pp.status.should be == Pay::PaymentPlan::INVALID
      pp.voucher_status.should be == Pay::PaymentPlan::ACCEPT_ALL
    end
  end
end

require 'spec_helper'

describe Trade::TransactionLogsController do
  before :each do
    @transaction_log = Trade::TransactionLog.new
    @transaction_log.log_type = Trade::TransactionLog::VICE
    @transaction_log.transaction_type = Trade::TransactionLog::CREDIT_BACK
    @transaction_log.transaction_datetime = Time.now
    @transaction_log.money_amount =1
    @transaction_log.actual_money_amount=1
    @transaction_log.payment_plan_id=1
    @transaction_log.credit_account_id=1
    @transaction_log.merchant_store_id =1
    @transaction_log.credit_delta =1
    @transaction_log.mobile ='1'
    @transaction_log.customer_name='1'
    @transaction_log.merchant_name='1'
    @transaction_log.terminal_num='1'
    @transaction_log.media_num ='1'
    @transaction_log.media_type='1'
    @transaction_log.sequence_number='1'
    @transaction_log.merchant_amount=1
    @transaction_log.status = Trade::TransactionLog::NORMAL
    @transaction_log.save!

    create_and_login_user('test', Users::SystemUser::DEPT_MANAGER)
  end

  describe 'index action' do
    it 'should render index template and response 200' do
      get :index
      response.code.should eq('200')
      response.should render_template('transaction_logs/index')
    end
  end
  describe 'show action' do
    it 'should show transaction log' do
      @transaction_log = Trade::TransactionLog.first!
      response.code.should eq('200')
    end
  end
end

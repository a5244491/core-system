require 'spec_helper'

describe Trade::VoucherTransactionLogsController do
  before :each do
    @log = Trade::VoucherTransactionLog.new
    @log.transaction_type = Trade::VoucherTransactionLog::ISSUE
    @log.transaction_datetime = Time.now
    @log.issuer_type = Member::VoucherMeta::SELF
    @log.issuer_name='1'
    @log.issuer_identifier=1
    @log.settler_type = Member::VoucherMeta::SELF
    @log.settler_name='1'
    @log.settler_identifier=1

    @log.denomination=100
    @log.deducted_amount=50
    @log.voucher_meta_code =1
    @log.voucher_unique_id =1
    @log.ref_id =1
    @log.primary_transaction_ref_id=1
    @log.issue_event=Trade::VoucherTransactionLog::SYSTEM
    @log.merchant_name='1'
    @log.merchant_store_id =1
    @log.merchant_num='1'
    @log.save!

    create_and_login_user('test', Users::SystemUser::DEPT_MANAGER)
  end

  describe 'index action' do
    it 'should render show template and response 200' do
      get :index
      response.code.should eq('200')
      response.should render_template('index')
    end
  end

  describe 'show action' do
    it 'should render show template and response 200' do
      @log = Trade::VoucherTransactionLog.first!
      get :show, :id => @log.id
      response.code.should eq('200')
      response.should render_template('show')
    end
  end
end

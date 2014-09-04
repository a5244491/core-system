require 'spec_helper'

describe External::Transaction::VoucherTransactionLogsAPI do
  describe 'query voucher transaction log' do
    before :each do
      @account = create(:individual_credit_account)

      @log = Trade::VoucherTransactionLog.new
      @log.transaction_type = Trade::VoucherTransactionLog::ISSUE
      @log.transaction_datetime = Time.now
      @log.issuer_type = Member::VoucherMeta::SELF
      @log.issuer_name='1'
      @log.issuer_identifier = 1
      @log.settler_type = Member::VoucherMeta::SELF
      @log.settler_name = '1'
      @log.settler_identifier = 1
      @log.credit_account_id = @account.id

      @log.denomination = 100
      @log.deducted_amount = 50
      @log.voucher_meta_code = 1
      @log.voucher_unique_id = 1
      @log.ref_id = 1
      @log.primary_transaction_ref_id = 1
      @log.issue_event = Trade::VoucherTransactionLog::SYSTEM
      @log.save!
    end

    it 'should get transaction by transaction_type issue' do
      get '/external/voucher_transaction_logs', query: {:transaction_type_eq => Trade::VoucherTransactionLog::ISSUE}
      response.status.should eq (200)

      body = JSON.parse response.body
      body['total'].should be == 1
      voucher_transaction_log = body['records'].first
      voucher_transaction_log['transaction_type'].should be == Trade::VoucherTransactionLog::ISSUE
    end

    it "get user's transaction log" do
      get '/external/voucher_transaction_logs', query: {:credit_account_external_id_eq => @account.external_id}
      response.status.should eq (200)
      body = JSON.parse response.body
      body['total'].should be == 1

      get '/external/voucher_transaction_logs', query: {:credit_account_external_id_eq =>'-1'}
      response.status.should eq (200)
      body = JSON.parse response.body
      body['total'].should be == 0
    end
  end
end
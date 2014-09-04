require 'spec_helper'

describe External::Transaction::TransactionLogsAPI do
  describe 'query transaction log' do
    before :each do
      @account = create(:individual_credit_account)
      @tl = Trade::TransactionLog.new
      @tl.log_type = Trade::TransactionLog::PRIMARY
      @tl.transaction_type = Trade::TransactionLog::CREDIT_BACK
      @tl.transaction_datetime = Time.now
      @tl.credit_account_id = @account.id
      @tl.credit_account_external_id = @account.external_id
      @tl.media_num = '123456'
      @tl.status = Trade::TransactionLog::NORMAL
      @tl.voucher_used_count = 100
      @tl.save!
    end

    it 'should get transaction by last 4 of media_num' do
      get '/external/transaction_logs', query: {credit_account_external_id_eq: @account.external_id, media_num_end_with: '3456'}
      response.status.should eq (200)
      body = JSON.parse response.body
      body['total'].should == 1
      transaction_log = body['records'].first
      transaction_log['media_num'].should == @tl.media_num.to_s
    end

    it 'should query transaction log by voucher used' do
      get '/external/transaction_logs', query: {credit_account_external_id_eq: @account.external_id, voucher_used_count_gt: 0}
      response.status.should eq (200)
      body = JSON.parse response.body
      body['total'].should == 1
      transaction_log = body['records'].first
      transaction_log['media_num'].should == @tl.media_num

    end
  end

end
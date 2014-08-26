require 'spec_helper'

describe Trade::TransactionLog do
  it 'should save' do
    Trade::TransactionLog.create!(log_type: Trade::TransactionLog::PRIMARY, transaction_type: Trade::TransactionLog::NONE, status: Trade::TransactionLog::NORMAL, transaction_datetime: Time.now)
    Trade::TransactionLog.primary_log.count.should be ==1
    Trade::TransactionLog.vice_log.count.should be ==0
    log = Trade::TransactionLog.first
    log.merchant_rate = 0.05
    log.save!
    log.checked.should be ==Trade::TransactionLog::NOT_CHECKED
  end

  it 'should not save if log_type is invalid' do
    expect {Trade::TransactionLog.create!}.to raise_error ActiveRecord::RecordInvalid
    expect {Trade::TransactionLog.create!(log_type: 9999)}.to raise_error ActiveRecord::RecordInvalid
  end
end

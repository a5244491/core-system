FactoryGirl.define do
  factory :transaction_log, class: Trade::TransactionLog do
    log_type Trade::TransactionLog::PRIMARY
    transaction_type Trade::TransactionLog::NONE
    status Trade::TransactionLog::NORMAL
    transaction_datetime Time.now
  end
end
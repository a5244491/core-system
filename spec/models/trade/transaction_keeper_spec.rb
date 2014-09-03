require 'spec_helper'

describe Trade::TransactionKeeper do
  it 'should reconfirm transactions' do
    t1 = Trade::NonePaymentPlanTransaction.create!(created_at: 5.minutes.ago, confirmed: true, status: 1, transaction_datetime: Time.now)
    t2 = Trade::NonePaymentPlanTransaction.create!(created_at: 4.minutes.ago, confirmed: true, status: 1, transaction_datetime: Time.now)
    t3 = Trade::NonePaymentPlanTransaction.create!(created_at: 2.minutes.ago, confirmed: true, status: 1, transaction_datetime: Time.now)
    t4 = Trade::NonePaymentPlanTransaction.create!(created_at: 1.minutes.ago, confirmed: true, status: 1, transaction_datetime: Time.now)

    Trade::TransactionKeeper.reconfirm_transactions(3.minutes)
    Trade::TransactionLog.where(ref_id: t1.ref_id).count.should be == 1
    Trade::TransactionLog.where(ref_id: t2.ref_id).count.should be == 1
    Trade::TransactionLog.where(ref_id: t3.ref_id).count.should be == 0
    Trade::TransactionLog.where(ref_id: t4.ref_id).count.should be == 0
  end

  it 'should clean up transactions' do
    t1 = Trade::NonePaymentPlanTransaction.create!(created_at: 5.minutes.ago, confirmed: false)
    t2 = Trade::NonePaymentPlanTransaction.create!(created_at: 4.minutes.ago, confirmed: false)
    t3 = Trade::NonePaymentPlanTransaction.create!(created_at: 2.minutes.ago, confirmed: false)
    t4 = Trade::NonePaymentPlanTransaction.create!(created_at: 1.minutes.ago, confirmed: false)

    Trade::TransactionKeeper.clean_up_transactions(3.minutes)
    Trade::TransactionArchive.count.should be == 2
    Trade::TransactionArchive.exists?(ref_id: t1.ref_id).should be_true
    Trade::TransactionArchive.exists?(ref_id: t2.ref_id).should be_true
    Trade::TransactionArchive.exists?(ref_id: t3.ref_id).should be_false
    Trade::TransactionArchive.exists?(ref_id: t4.ref_id).should be_false
    Trade::Transaction.count.should be == 2
    Trade::Transaction.exists?(ref_id: t1.ref_id).should be_false
    Trade::Transaction.exists?(ref_id: t2.ref_id).should be_false
    Trade::Transaction.exists?(ref_id: t3.ref_id).should be_true
    Trade::Transaction.exists?(ref_id: t4.ref_id).should be_true
  end
end
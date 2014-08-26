require 'spec_helper'

describe Member::IndividualCreditAccount do
  describe 'when no cashing card exists' do
    describe 'failure cases' do
      it 'should not apply credit cashing if no bank card is bond' do
        @account = create(:individual_credit_account, usable_credit: 8000)
        expect { @account.submit_credit_cashing_application!(400) }.to raise_error Member::CreditCashingApplication::NoCashingAccountError
      end

      it 'should not apply credit cashing if no cashing card is specified' do
        @account =create(:individual_credit_account_with_bank_card, usable_credit: 8000)
        expect { @account.submit_credit_cashing_application!(400) }.to raise_error Member::CreditCashingApplication::NoCashingAccountError
      end
    end

    describe 'cashing card exists' do
      before :each do
        @account =create(:individual_credit_account_with_cashing_card, usable_credit: 8000)
      end
      it 'should apply credit cashing' do
        @account.submit_credit_cashing_application!(5000)
        @account.usable_credit.should be ==3000
        @account.locked_credit.should be ==5000
        Member::CreditCashingApplication.count.should be ==1
        application = Member::CreditCashingApplication.first
        application.bank_card.should be ==@account.bank_cards.first.card_num
        application.bank_name.should be ==@account.bank_cards.first.bank_name
        application.amount.should be ==5000
        application.status.should be ==Member::CreditCashingApplication::PROCESSING
      end

      it 'should not apply credit cashing if amount is not valid' do
        expect { @account.submit_credit_cashing_application!(5100) }.to raise_error ArgumentError
      end
    end
  end

  describe 'issue voucher' do
    before :each do
      @account = create(:individual_credit_account)
      @voucher_meta = create(:active_voucher_meta, initial_amount: 1)
      @voucher_meta_no_limit = create(:active_voucher_meta)
      @voucher_meta_account_limit = create(:active_voucher_meta, initial_amount: 2, limit_per_account: 1)
    end

    it 'should issues voucher by meta code' do
      @account.issue_voucher(@voucher_meta.code)
      @account.vouchers.size.should be ==1
      voucher_log = Trade::VoucherTransactionLog.first
      voucher_log.should_not be_nil
      voucher_log.transaction_type.should be ==Trade::VoucherTransactionLog::ISSUE
      voucher_log.issue_event.should be ==Trade::VoucherTransactionLog::SYSTEM
      voucher_log.voucher_meta_code.should be ==@voucher_meta.code
      voucher_log.voucher_unique_id.should be ==@account.vouchers.first.unique_id
      @voucher_meta.reload.issued_count.should be ==1
    end

    it 'should issues voucher by meta object' do
      @account.issue_voucher(@voucher_meta)
      @account.vouchers.size.should be ==1
      voucher_log = Trade::VoucherTransactionLog.first
      voucher_log.should_not be_nil
      voucher_log.transaction_type.should be ==Trade::VoucherTransactionLog::ISSUE
      voucher_log.issue_event.should be ==Trade::VoucherTransactionLog::SYSTEM
      voucher_log.voucher_meta_code.should be ==@voucher_meta.code
      voucher_log.voucher_unique_id.should be ==@account.vouchers.first.unique_id
      @voucher_meta.reload.issued_count.should be ==1
    end


    it 'should not issue voucher if voucher is not valid' do
      @voucher_meta.status = Member::VoucherMeta::INACTIVE
      @voucher_meta.save!
      expect { @account.issue_voucher(@voucher_meta.code) }.to raise_error(Member::VoucherMeta::VoucherNotAvailable)
    end

    it 'should not issue voucher if voucher run out' do
      @account.issue_voucher(@voucher_meta.code)
      expect { @account.issue_voucher(@voucher_meta.code) }.to raise_error(Member::VoucherMeta::VoucherAmountExceeded)
    end

    it 'should issue voucher for voucher without number limit' do
      @account.issue_voucher(@voucher_meta_no_limit.code)
      @account.issue_voucher(@voucher_meta_no_limit.code)
      @account.issue_voucher(@voucher_meta_no_limit.code)
      @account.vouchers.size.should be ==3
      @voucher_meta_no_limit.reload.issued_count.should be ==3
    end

    it 'should not issue voucher if per account limit reached' do
      @account.issue_voucher(@voucher_meta_account_limit.code)
      expect { @account.issue_voucher(@voucher_meta_account_limit.code) }.to raise_error(Member::VoucherMeta::VoucherLimitPerAccountExceeded)
    end

    it 'should issue voucher to different account' do
      @account1 = Member::IndividualCreditAccount.create!(name: 'test1', address: 'testa', mobile: '1234561', usable_credit: 8000)
      @account.issue_voucher(@voucher_meta_account_limit.code)
      @account1.issue_voucher(@voucher_meta_account_limit.code)
      @account.vouchers.size.should be ==1
      @account1.vouchers.size.should be ==1
    end

    describe 'issue voucher with sequence number' do
      before :each do
        @sequence = create(:sequence, numbers: %w(1234 1235))
        @voucher_meta = create(:active_voucher_meta, sequence: @sequence)
      end

      it 'should issue voucher' do
        @account.issue_voucher(@voucher_meta).sequence_number.should be =='1234'
        Trade::VoucherTransactionLog.first.voucher_sequence_number.should be =='1234'
        @account.issue_voucher(@voucher_meta).sequence_number.should be =='1235'
        expect { @account.issue_voucher(@voucher_meta) }.to raise_error Member::VoucherMeta::VoucherAmountExceeded
      end
    end

    describe 'membership management' do
      before :each do
        @store = create(:merchant_store)
        @group = create(:merchant_group)
        @account = create(:individual_credit_account, mobile: '112312323')
      end

      it 'should becomes member of a store' do
        @account.becomes_member_of(@store)
        @account.reload
        @account.merchant_stores.count.should be ==1
        @account.merchant_stores.first.should be ==@store
        @store.reload
        @store.member_accounts.count.should be ==1
        @store.member_accounts.first.should be ==@account
      end

      it 'should not duplicate memeber of a store' do
        @account.becomes_member_of(@store)
        @account.becomes_member_of(@store)

        @account.reload
        @account.merchant_stores.count.should be ==1
        @account.merchant_stores.first.should be ==@store
        @store.reload
        @store.member_accounts.count.should be ==1
        @store.member_accounts.first.should be ==@account
      end

      it 'should becomes member of a group' do
        @account.becomes_member_of(@group)
        @account.reload
        @account.merchant_groups.count.should be ==1
        @account.merchant_groups.first.should be ==@group
        @group.reload
        @group.member_accounts.count.should be ==1
        @group.member_accounts.first.should be ==@account
      end

      it 'should duplicate member of a group' do
        @account.becomes_member_of(@group)
        @account.becomes_member_of(@group)

        @account.reload
        @account.merchant_groups.count.should be ==1
        @account.merchant_groups.first.should be ==@group
        @group.reload
        @group.member_accounts.count.should be ==1
        @group.member_accounts.first.should be ==@account
      end
    end
  end
end

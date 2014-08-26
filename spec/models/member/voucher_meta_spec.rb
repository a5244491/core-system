require 'spec_helper'

describe Member::VoucherMeta do
  describe 'validations' do
    it 'should fill up aliases' do
      voucher_meta = Member::VoucherMeta.create!
      voucher_meta.global?.should be_true
      voucher_meta.aliases.should_not be_nil
      voucher_meta.amount_left.should be ==-1
      voucher_meta.initial_amount.should be ==-1
    end

    it 'should check usable correctly' do
      voucher_meta = create(:active_voucher_meta, valid_from: 5.minutes.ago, valid_till: 5.minutes.from_now)
      voucher_meta.active?.should be_true
      voucher_meta = create(:active_voucher_meta, valid_from: 5.minutes.from_now, valid_till: 5.minutes.ago)
      voucher_meta.active?.should be_false
    end

    it 'should sync initial amount and amount left' do
      voucher_meta = Member::VoucherMeta.create!(initial_amount: 100)
      voucher_meta.amount_left.should be ==100
      voucher_meta.update(initial_amount: 50)
      voucher_meta.amount_left.should be ==50
      voucher_meta.update(initial_amount: -1)
      voucher_meta.amount_left.should be ==-1
    end
  end

  describe 'merchant stores and groups' do
    before :each do
      @voucher_meta = create(:voucher_meta)
      @store = create(:merchant_store)
      @group = create(:merchant_group)
    end

    it 'should assign store to voucher meta' do
      @voucher_meta.merchant_store = @store
      @voucher_meta.save!
      @voucher_meta.reload.merchant_store.id.should be ==@store.id
    end

    it 'should assign store to voucher meta' do
      @voucher_meta.merchant_group = @group
      @voucher_meta.save!
      @voucher_meta.reload.merchant_group.id.should be ==@group.id
    end
  end

  describe 'credit account' do
    before :each do
      @voucher_meta = create(:voucher_meta, denomination: 10000)
      @credit_account = create(:individual_credit_account)
    end

    it 'should add vouchers to credit account' do
      @credit_account.vouchers << @voucher_meta.issue_voucher
      @credit_account.save!
      @credit_account.vouchers.first.denomination.should be ==10000
    end
  end

  describe 'issue vouchers' do
    before :each do
      @voucher_meta = create(:voucher_meta, denomination: 10000, initial_amount: 1)
    end

    it 'should issue voucher' do
      voucher = @voucher_meta.issue_voucher
      voucher.denomination.should be ==@voucher_meta.denomination
      @voucher_meta.reload.amount_left.should be ==0
      expect{@voucher_meta.issue_voucher}.to raise_error Member::VoucherMeta::VoucherAmountExceeded
    end
  end

  describe 'show applicable store name' do
    before :each do
      @store = create(:merchant_store)
      @group = create(:merchant_group, display_name: 'test_display')
    end
    it 'should show correct applicable store name' do
      voucher_meta = create(:voucher_meta)
      voucher_meta.applicable_store_name.should be =='联盟商户'
      voucher_meta = create(:voucher_meta, store: @store)
      voucher_meta.applicable_store_name.should be ==@store.name
      voucher_meta = create(:voucher_meta, group: @group)
      voucher_meta.applicable_store_name.should be ==@group.display_name
    end
  end
end

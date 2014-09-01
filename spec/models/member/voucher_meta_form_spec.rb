require 'spec_helper'

describe Member::VoucherMetaForm do
  describe 'parameter conversion' do
    before :each do
      @form = Member::VoucherMetaForm.new(Member::VoucherMeta.new)
    end
    it 'should do limit per account conversion' do
      @form.validate({
          limit_per_account_on: 'true',
          limit_per_account: '100'
                     }).should be_true
      @form.limit_per_account.should be == Member::VoucherMeta::DEFAULT_LIMIT_PER_ACCOUNT
      @form.limit_per_account_on.should be == true

      @form.validate({
                         limit_per_account_on: 'false',
                         limit_per_account: '100'
                     }).should be_true
      @form.limit_per_account.should be == 100
      @form.limit_per_account_on.should be == false
    end

    it 'should do initial amount conversion' do
      @form.validate({
                         initial_amount_on: 'true',
                         initial_amount: '100'
                     }).should be_true
      @form.initial_amount.should be == Member::VoucherMeta::DEFAULT_LIMIT_PER_ACCOUNT
      @form.initial_amount_on.should be == true

      @form.validate({
                         initial_amount_on: 'false',
                         initial_amount: '100'
                     }).should be_true
      @form.initial_amount.should be == 100
      @form.initial_amount_on.should be == false
    end

    describe 'applicable target conversion' do
      before :each do
        @merchant_store = create(:merchant_store)
        @merchant_group = create(:merchant_group)
      end

      it 'should validate merchant store' do
        @form.validate({
                           applicable_type: Member::VoucherMeta::SINGLE_STORE.to_s,
                           applicable_target_name: @merchant_store.name
                       }).should be_true
        @form.merchant_store.should be == @merchant_store

        @form.validate({
                           applicable_type: Member::VoucherMeta::SINGLE_STORE.to_s,
                           applicable_target_name: 'does not exists'
                       }).should be_false
        @form.merchant_store.should be_nil
        @form.errors.full_messages.to_s.should include('商户does not exists不存在')
      end

      it 'should validate merchant group' do
        @form.validate({
                           applicable_type: Member::VoucherMeta::STORE_GROUP.to_s,
                           applicable_target_name: @merchant_group.name
                       }).should be_true
        @form.merchant_group.should be == @merchant_group

        @form.validate({
                           applicable_type: Member::VoucherMeta::STORE_GROUP.to_s,
                           applicable_target_name: 'does not exists'
                       }).should be_false
        @form.merchant_group.should be_nil
        @form.errors.full_messages.to_s.should include('群组does not exists不存在')
      end
    end

    describe 'settler and issuer identifier conversion' do
      before :each do
        @merchant_store = create(:merchant_store)
      end

      it 'should validate bank/partner settler and issuer' do
        @form.validate({
                           settler_type: Member::VoucherMeta::BANK.to_s,
                           settler_name: 'bank',
                           issuer_type: Member::VoucherMeta::PARTNER.to_s,
                           issuer_name: 'partner'
                       }).should be_true
        @form.settler_identifier.should be == 'bank'
        @form.issuer_identifier.should == 'partner'
      end

      it 'should validate merchant store issuer' do
        @form.validate({
                           settler_type: Member::VoucherMeta::MERCHANT.to_s,
                           settler_name: @merchant_store.name,
                       }).should be_true
        @form.settler_identifier.should be == @merchant_store.merchant_number
      end
    end
  end
end
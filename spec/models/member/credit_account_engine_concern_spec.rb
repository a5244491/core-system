require 'spec_helper'

describe Member::CreditAccount do
  describe 'apply consumption credit' do
    before :each do
      @credit_account = create(:individual_credit_account)
    end

    it 'should apply consumption credit' do
      @credit_account.apply_consumption_credit!(100, nil?)
      @credit_account = Member::CreditAccount.first
      @credit_account.total_credit.should be == 100
      @credit_account.usable_credit.should be == 100
      @credit_account.cashed_credit.should be == 0
      @credit_account.locked_credit.should be == 0
      @credit_account.consumption_credit.should be == 100
      @credit_account.referer_credit.should be == 0
      @credit_account.referee_credit.should be == 0

      @credit_account.apply_consumption_credit!(50, nil)
      @credit_account = Member::CreditAccount.first
      @credit_account.total_credit.should be == 150
      @credit_account.usable_credit.should be == 150
      @credit_account.cashed_credit.should be == 0
      @credit_account.locked_credit.should be == 0
      @credit_account.consumption_credit.should be == 150
      @credit_account.referer_credit.should be == 0
      @credit_account.referee_credit.should be == 0
    end
  end

  describe 'apply referer credit' do
    before :each do
      @credit_account = create(:individual_credit_account, referer_mobile: '9999888')
      @referer_account = @credit_account.referer_account
    end

    it 'should apply referer credit when there is no referer' do
      @referer_account.apply_referer_credit!(100).should be_false
      @referer_account = Member::CreditAccount.where(mobile: @credit_account.mobile).first
      @referer_account.total_credit.should be == 0
      @referer_account.usable_credit.should be == 0
      @referer_account.cashed_credit.should be == 0
      @referer_account.locked_credit.should be == 0
      @referer_account.consumption_credit.should be == 0
      @referer_account.consumption_times.should be == 0
      @referer_account.referer_credit.should be == 0
      @referer_account.referee_credit.should be == 0
    end

    it 'should apply referer credit' do
      @credit_account.apply_referer_credit!(30).should be_true
      @credit_account = Member::CreditAccount.where(mobile: @credit_account.mobile).first
      @referer_account = Member::CreditAccount.where(mobile: @referer_account.mobile).first
      @credit_account.total_credit.should be == 0
      @credit_account.usable_credit.should be == 0
      @credit_account.cashed_credit.should be == 0
      @credit_account.locked_credit.should be == 0
      @credit_account.consumption_credit.should be == 0
      @credit_account.consumption_times.should be == 0
      @credit_account.referer_credit.should be == 0
      @credit_account.referee_credit.should be == 30

      @referer_account.total_credit.should be == 30
      @referer_account.usable_credit.should be == 30
      @referer_account.cashed_credit.should be == 0
      @referer_account.locked_credit.should be == 0
      @referer_account.consumption_credit.should be == 0
      @referer_account.consumption_times.should be == 0
      @referer_account.referer_credit.should be == 30
      @referer_account.referee_credit.should be == 0
    end
  end
end
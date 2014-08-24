require 'spec_helper'

describe Member::CreditAccount do
  describe 'persistence' do
    it 'should save' do
      account = Member::IndividualCreditAccount.create!(name: 'test', address: 'testa', mobile: '123456')
      account.should_not be_nil
      account.external_id.should_not be_nil
      account.total_credit.should == 0
      account.usable_credit.should == 0
      account.referer_credit.should == 0
      account.referee_credit.should == 0
      account.locked_credit.should == 0
      account.cashed_credit.should == 0
      account.consumption_credit.should == 0
      account.consumption_times.should == 0
      account.referer_account.should be_nil
      account.create_referer_account(mobile: '12345611').should_not be_false

      Member::MerchantCreditAccount.create.should be_true
    end


    it 'should prevent concurrent modification' do
      account1 = Member::IndividualCreditAccount.create!(mobile: '123456')
      account2 = Member::CreditAccount.first
      account2.total_credit = 100
      account2.save!
      account1.total_credit = 50
      expect { account1.save! }.to raise_error ActiveRecord::StaleObjectError
      Member::CreditAccount.first.total_credit.should == 100
    end

    it 'should not save when mobile has been taken' do
      account = Member::IndividualCreditAccount.create!(name: 'test', address: 'testa', mobile: '123456')
      expect {
        Member::IndividualCreditAccount.create!(name: 'test', address: 'testa', mobile: account.mobile)
      }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'should not save when mobile is nil' do
      expect {
        Member::IndividualCreditAccount.create!(name: 'test', address: 'testa')
      }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe 'manage bankcard ' do
    before :each do
      @account = create(:individual_credit_account)
    end

    it 'should add bank card' do
      @account.add_bank_card('1111111111111111111111', Member::BankCard::DEBIT_CARD)
      @account.bank_cards.count.should == 1
    end

    it 'should not add bank card if card is taken' do
      @account.add_bank_card('1111111111111111111111', Member::BankCard::DEBIT_CARD)
      expect { @account.add_bank_card('1111111111111111111111', Member::BankCard::DEBIT_CARD) }.to raise_error Member::BankCardTakenError
    end

    it 'should not add bank card if card number exceeds limit' do
      Member::IndividualCreditAccount::MAX_BIND_CARD_NUM.times do |i|
        @account.add_bank_card("111111111111111111111#{i}", Member::BankCard::DEBIT_CARD)
      end
      expect { @account.add_bank_card('111111111111111111111199', Member::BankCard::DEBIT_CARD) }.to raise_error Member::ExceedsBankCardLimitsError
    end
  end

  describe 'credit cashing management' do
    before :each do
      @account =create(:individual_credit_account, usable_credit: 1000)
    end

    it 'should apply credit cashing' do
      @account.apply_credit_cashing!(400)
      @account = Member::IndividualCreditAccount.find(@account.id)
      @account.usable_credit.should == 600
      @account.locked_credit.should == 400
    end

    it 'should reject credit cashing' do
      @account.apply_credit_cashing!(400)
      @account.reject_credit_cashing!(400)
      @account = Member::IndividualCreditAccount.find(@account.id)
      @account.usable_credit.should == 1000
      @account.locked_credit.should == 0
    end

    it 'should approve credit cashing' do
      @account.apply_credit_cashing!(400)
      @account.approve_credit_cashing!(400)
      @account = Member::IndividualCreditAccount.find(@account.id)
      @account.usable_credit.should == 600
      @account.locked_credit.should == 0
      @account.cashed_credit.should == 400
    end
  end

  it 'should diff mobile number' do
    credit_account = Member::CreditAccount.new
    credit_account.mobile = '13982007900'
    credit_account.diff_mobile.should  ==  '139****7900'
  end
end

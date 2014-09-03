require 'spec_helper'

describe Member::BankCard do
  before :each do
    @account = create(:individual_credit_account)
  end
  it 'should save' do
    @account.bank_cards.create!(media_num: '1234567812345678',card_type: Member::BankCard::DEBIT_CARD)
    @account.bank_cards.count.should be ==1
    @account.payment_media.count.should be ==1
    bank_card = @account.bank_cards.first
    bank_card.media_type.should be =='bank_card'
    bank_card.credit_earned.should be ==0
  end

  it 'should prevent concurrent modification' do
    bank_card1 = @account.bank_cards.create!(media_num: '1234567812345678',card_type: Member::BankCard::DEBIT_CARD)
    bank_card2 = @account.bank_cards.first
    bank_card1.credit_earned = 100
    bank_card2.credit_earned = 50
    bank_card2.card_type = Member::BankCard::DEBIT_CARD
    bank_card2.save!
    expect {bank_card1.save!}.to raise_error ActiveRecord::StaleObjectError
    Member::BankCard.first.credit_earned.should be ==50
  end


  it 'should diff card number' do
    bank_card = Member::BankCard.new
    bank_card.media_num = '12345678901234567890'
    bank_card.diff_card_number.should  ==  '****7890'
  end
end

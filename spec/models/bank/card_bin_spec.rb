require 'spec_helper'

describe Bank::CardBin do
  it 'should save' do
    Bank::CardBin.create!(card_code: '0011', bank_name: 'ccb', length: 19, bank_bin: '1234', organization: 1, card_type: 1).should be_true
  end

  it 'should match card bin' do
    Bank::CardBin.create!(card_code: '0011', bank_name: 'ccb1', length: 19, bank_bin: '1234', organization: 1, card_type: 1)
    card_bin2 = Bank::CardBin.create!(card_code: '0012', bank_name: 'ccb2', length: 19, bank_bin: '12345', organization: 1, card_type: 2)
    card_bin3 = Bank::CardBin.create!(card_code: '0013', bank_name: 'ccb3', length: 19, bank_bin: '123456', organization: 0, card_type: 3)
    match_card_bin2 = Bank::CardBin.card_bin_match '123457777'
    card_bin2.bank_bin.should eq match_card_bin2.bank_bin
    match_card_bin3 = Bank::CardBin.card_bin_match '123456666'
    card_bin3.bank_bin.should eq match_card_bin3.bank_bin
  end
end

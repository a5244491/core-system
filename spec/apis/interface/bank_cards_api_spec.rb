require 'spec_helper'

describe External::Member::BankCardsAPI do

  before :each do
    @account = create(:individual_credit_account, mobile: '13982007900')
  end


  describe 'get /bank_cards' do
    before :each do
      (0...2).each do |i|
        @account.bank_cards.create!(
            card_num: "123456789012345#{i}",
            card_type: Member::BankCard::DEBIT_CARD,
            bank_name: "bank_name#{i}",
            cashing_card: false,
            credit_earned: 100
        )
      end
    end
    it 'get bank cards by external_id' do
      pattern = {
          records: [{
                        id: @account.bank_cards.first.id,
                        card_type: @account.bank_cards.first.card_type,
                        bank_name: @account.bank_cards.first.bank_name,
                        cashing_card: @account.bank_cards.first.cashing_card,
                        credit_earned: @account.bank_cards.first.credit_earned,
                        created_at: @account.bank_cards.first.created_at
                    },
                    {
                        id: @account.bank_cards.second.id,
                        card_type: @account.bank_cards.second.card_type,
                        bank_name: @account.bank_cards.second.bank_name,
                        cashing_card: @account.bank_cards.second.cashing_card,
                        credit_earned: @account.bank_cards.second.credit_earned,
                        created_at: @account.bank_cards.second.created_at

      }

          ],
          total: 2
      }
      get "/external/members/#{@account.external_id}/bank_cards"
      response.status.should be == 200
      response.body.should match_json_expression(pattern)
    end
  end


  describe 'post /bank_cards' do
    it 'bind fail since of  Card number is too short (minimum is 16 characters)' do
      post "/external/members/#{@account.external_id}/bank_cards", :card_num => '123', :card_type => Member::BankCard::DEBIT_CARD, :bank_name => 'CCB'
      response.status.should eq (422)
      body = JSON.parse(response.body)
      body['error'].should be == 'INVALID_INPUT'
    end

    it 'bind fail since of  Card number is too long (maximum is 30 characters)' do
      post "/external/members/#{@account.external_id}/bank_cards", :card_num => '1235678901235678901235678901234567890', :card_type => Member::BankCard::DEBIT_CARD, :bank_name => 'CCB'
      response.status.should eq (422)
      body = JSON.parse(response.body)
      body['error'].should be == 'INVALID_INPUT'
    end

    it 'bind fail since of cards greater than 5' do
      (0...5).each do |i|
        @account.bank_cards.create!(
            card_num: "123456789012345#{i}",
            card_type: Member::BankCard::DEBIT_CARD,
            bank_name: "bank_name#{i}",
            cashing_card: false,
            credit_earned: 100
        )
      end
      post "/external/members/#{@account.external_id}/bank_cards", :card_num => '1234567890123456', :card_type => Member::BankCard::DEBIT_CARD, :bank_name => 'CCB'
      response.status.should eq (419)
      body = JSON.parse(response.body)
      body['error'].should eq 'BANK_CARD_EXCEEDS_LIMIT'
    end

    it 'bind fail since of this card already bind' do
      @account.bank_cards.create!(
          card_num: '123456789012345',
          card_type: Member::BankCard::DEBIT_CARD,
          bank_name: 'bank_name',
          cashing_card: false,
          credit_earned: 100
      )
      post "/external/members/#{@account.external_id}/bank_cards", :card_num => '123456789012345', :card_type => Member::BankCard::DEBIT_CARD, :bank_name => 'CCB'
      response.status.should eq (419)
      body = JSON.parse(response.body)
      body['error'].should eq 'BANK_CARD_EXISTS'
    end

    it 'should success' do
      post "/external/members/#{@account.external_id}/bank_cards", :card_num => '12345678901234566', :card_type => Member::BankCard::DEBIT_CARD, :bank_name => 'CCB'
      response.status.should be == 200
      JSON.parse(response.body)['success'].should eq 'success'
      bank_card = @account.bank_cards.first
      bank_card.bank_name.should be == 'CCB'
      bank_card.card_num.should be == '12345678901234566'
    end
  end

  describe 'on update' do
    before :each do
      @bank_card = @account.bank_cards.create!(
          card_num: '123456789012345',
          card_type: Member::BankCard::DEBIT_CARD,
          bank_name: 'bank_name',
          cashing_card: false,
          credit_earned: 100
      )
    end
    it 'set cashing card fail this card is credit card' do
      @bank_card.update(card_type: Member::BankCard::CREDIT_CARD)
      put "/external/members/#{@account.external_id}/bank_cards/#{@bank_card.id}", :cashing_card => true
      response.status.should eq 419
      body = JSON.parse(response.body)
      body['error'].should eq 'CANT_SET_CREDIT_CARD_AS_CASHING_CARD'
    end

    it 'set cashing card success' do
      put "/external/members/#{@account.external_id}/bank_cards/#{@bank_card.id}", :cashing_card => true
      response.should be_ok
      JSON.parse(response.body)['success'].should eq 'success'
      bank_card = @account.bank_cards.first
      bank_card.cashing_card.should be_true
    end

    it 'set cashing card2 unset cashing card1' do
      bank_card1 = @account.bank_cards.build
      bank_card1.card_num = '1234567890123450'
      bank_card1.credit_earned = '0'
      bank_card1.card_type = Member::BankCard::DEBIT_CARD
      bank_card1.bank_name = 'ICBC'
      bank_card1.cashing_card = true
      bank_card1.save!

      put "/external/members/#{@account.external_id}/bank_cards/#{@bank_card.id}", :cashing_card => true
      response.should be_ok
      JSON.parse(response.body)['success'].should eq 'success'
      bank_card1.reload.cashing_card.should be_false
      @bank_card.reload.cashing_card.should be_true
    end

    it 'unset cashing card' do
      @bank_card.set_cashing_card(true)
      put "/external/members/#{@account.external_id}/bank_cards/#{@bank_card.id}", :cashing_card => false
      response.should be_ok
      JSON.parse(response.body)['success'].should eq 'success'
      @bank_card.reload.cashing_card.should be_false
    end

  end

  describe 'on delete' do
    before :each do
      @bank_card = @account.bank_cards.create!(
          card_num: '123456789012345',
          card_type: Member::BankCard::DEBIT_CARD,
          bank_name: 'bank_name',
          cashing_card: false,
          credit_earned: 100
      )
    end
    it 'should delete bank card ' do
      delete "/external/members/#{@account.external_id}/bank_cards/#{@bank_card.id}", :cashing_card => false
      response.should be_ok
      JSON.parse(response.body)['success'].should eq 'success'
      Member::BankCard.exists?(@bank_card.id).should be_false
    end

  end
end
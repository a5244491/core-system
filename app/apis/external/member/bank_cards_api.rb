module External
  module Member
    class BankCardsAPI < Grape::API
      namespace :members do
        params do
          requires :credit_account_external_id, type: String
        end
        namespace ':credit_account_external_id' do
          before do
            @credit_account = ::Member::IndividualCreditAccount.where(external_id: params[:credit_account_external_id]).first!
          end

          get 'bank_cards', jbuilder: 'external/member/bank_cards/index' do
            @bank_cards = @credit_account.bank_cards
            @total = @bank_cards.size
          end

          post '/bank_cards' do
            begin
              @credit_account.bind_bank_card(params[:card_num], params[:bank_name], params[:card_type])
              render_success
            rescue ::Member::BankCardTakenError
              render_error('BANK_CARD_EXISTS')
            rescue ::Member::ExceedsBankCardLimitsError
              render_error('BANK_CARD_EXCEEDS_LIMIT')
            end
          end

          params do
            requires :id, type: Integer
          end
          namespace '/bank_cards/:id' do
            before do
              @bank_card = @credit_account.bank_cards.find(params[:id])
            end

            params do
              requires :cashing_card
            end
            put do
              if @bank_card.card_type == ::Member::BankCard::CREDIT_CARD
                render_error('CANT_SET_CREDIT_CARD_AS_CASHING_CARD')
              else
                @bank_card.set_cashing_card(params[:cashing_card].to_bool)
                render_success
              end
            end

            delete do
              @bank_card.destroy
              render_success
            end
          end
        end
      end
    end
  end
end
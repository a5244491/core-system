#encoding:utf-8
module Engine
  module POS
    class CreditsAPI < Grape::API
      helpers Engine::POS::PosUtils
      before do
        authenticate!
        check_merchant!
      end

      params do
        requires :merchant_num, type: String, desc: 'the merchant number of the merchant that performs the operation'
      end
      namespace :credits do
        desc 'return usable credits of the user based on bank number', {
            notes: <<-NOTE
                queries the user's credit

                * on success, response body should be

                   {
                      "msg_screen": "string"
                   }
                   the POS system should indicate POS terminal to print value of 'msg_screen' on POS screen

                * on failure


                 1. http 419, response body should be
                   {
                      "msg_screen": "string"
                   }
                   the POS system should indicate POS terminal to print value of 'msg_screen' on POS screen

                 2. none 419/200 http code, means there were system errors, the pos terminal should indicate POS terminal to print
                   something like 'operation failed' on POS stream
            NOTE
        }
        params do
          requires :bank_card, type: String, desc: 'the bank card number of the user'
        end
        get do
          bank_card = Member::BankCard.where(media_num: params[:bank_card]).first
          if bank_card.nil?
            print_pos_error(MessageProperties::NOT_MEMBER)
          else
            credit_account = bank_card.credit_account
            print_pos_message("您的可用积分为:#{credit_account.nil? ? 0 : credit_account.usable_credit}")
          end
        end
      end
    end
  end
end
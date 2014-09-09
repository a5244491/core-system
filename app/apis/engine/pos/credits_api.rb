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
        requires :merchant_num
      end
      namespace :credits do
        params do
          requires :bank_card, type: String
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
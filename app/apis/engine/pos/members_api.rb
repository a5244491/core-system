module Engine
  module POS
    class MembersAPI < Grape::API
      helpers CoreEngineHelper
      helpers Engine::POS::PosUtils
      before do
        check_merchant!
      end


      resources :members do
        params do
          requires :bank_card, type: String
        end
        get do
          if Member::BankCard.exists?(media_num: params[:bank_card])
            print_pos_message(MessageProperties::IS_MEMBER_CARD)
          else
            print_pos_message(MessageProperties::IS_NOT_MEMBER_CARD)
          end
        end

        params do
          requires :bank_card, type: String
          requires :mobile, type: String
        end
        put '/', jbuilder: 'engine/pos/members/update' do
          mobile = params[:mobile]
          bank_card = params[:bank_card]
          print_pos_error(MessageProperties::INVALID_MOBILE) unless valid_mobile?(mobile)
          account = Member::IndividualCreditAccount.where(mobile: mobile).first
          if account.nil?
            print_pos_error(MessageProperties::NOT_MEMBER)
          else
            begin
              account.transaction do
                account.bind_bank_card(bank_card)
                account.becomes_member_of(current_merchant)
              end
              @receipt = Trade::Receipt.new(MessageProperties::TRAN_TYPE_NEW_CARD)
              @receipt.extra_rows << '新卡绑定成功，请登录爱刷平台管理及使用您的积分'
              send_sms(mobile, %Q{尊敬的爱刷会员，您已成功绑定尾号为#{bank_card.to_s[-4..-1]}的银行卡, 您可以使用该银行卡立享爱刷超值服务。www.aishua.cn【爱刷】})
              MarketingRuleWorker.perform_async(Merchant::MarketingRule::BIND_CARD, account.id, current_merchant.id)
            rescue Member::BankCardTakenError
              print_pos_error(MessageProperties::BANK_CARD_EXISTS)
            rescue Member::ExceedsBankCardLimitsError
              print_pos_error(MessageProperties::BANK_CARD_EXCEEDS_LIMIT)
            rescue ActiveRecord::RecordInvalid
              print_pos_error(MessageProperties::WRONG_BANK_CARD_NUM)
            end
          end
        end

        params do
          requires :bank_card, type: String
          requires :mobile, type: String
        end
        post '/', jbuilder: 'engine/pos/members/create' do
          mobile = params[:mobile]
          bank_card = params[:bank_card]
          account = Member::IndividualCreditAccount.where(mobile: mobile).first
          if not account.nil?
            print_pos_error(MessageProperties::MEMBER_EXISTS)
          elsif not valid_mobile?(mobile)
            print_pos_error(MessageProperties::INVALID_MOBILE)
          else
            begin
              Member::IndividualCreditAccount.transaction do
                account = Member::IndividualCreditAccount.create_account(mobile: mobile, bank_card: bank_card, referer_account: current_merchant.credit_account)
                account.becomes_member_of(current_merchant)
              end
              @receipt = Trade::Receipt.new(MessageProperties::TRAN_TYPE_NEW_MEMBER)
              @receipt.extra_rows << '已成功开通爱刷会员并绑定1张银行卡，请访问爱刷优惠官网注册帐号自动激活爱刷会员资格(注册时请使用注册手机号)'
              send_sms(mobile, %Q{您已成功绑定尾号为#{bank_card.to_s[-4..-1]}的银行卡，可使用该卡立享爱刷超值服务。请访问www.aishua.cn注册账号管理和使用积分【爱刷】})
              MarketingRuleWorker.perform_async(Merchant::MarketingRule::REGISTER, account.id, current_merchant.id)
            rescue Member::BankCardTakenError
              print_pos_error(MessageProperties::BANK_CARD_EXISTS)
            rescue ActiveRecord::RecordInvalid
              print_pos_error(MessageProperties::WRONG_BANK_CARD_NUM)
            end
          end
          status 200
        end
      end
    end
  end
end
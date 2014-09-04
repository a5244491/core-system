module Merchant
  class VoucherAction < Merchant::PostAction
    validates_presence_of :voucher_meta

    class << self
      def sti_name
        Merchant::PostAction::ISSUE_VOUCHER
      end
    end

    def perform_action(credit_account:, merchant_store: nil, trigger_event: nil, master_log: nil)
      unless credit_account.nil?
        issue_event = case trigger_event
                        when Merchant::MarketingRule::BIND_CARD, Merchant::MarketingRule::REGISTER
                          Trade::VoucherTransactionLog::SYSTEM
                        when Merchant::MarketingRule::TRANSACTION
                          Trade::VoucherTransactionLog::CONSUMPTION
                        else
                          Trade::VoucherTransactionLog::SYSTEM
                      end
        issued = 0
        self.voucher_count.to_i.times do
          begin
            credit_account.issue_voucher(voucher_meta,
                                         issue_event: issue_event,
                                         merchant_store: merchant_store,
                                         master_log: master_log
            )
            issued = issued + 1
          rescue Member::VoucherMeta::VoucherException => e
            logger.error "post action cant not issue voucher #{voucher_meta.aliases}/#{voucher_meta.code} due to  #{e.class}: #{e.message}"
          end
        end
        if issued > 0
          begin
            SmsWorker.perform_async(credit_account.mobile, sms_text(issued))
          rescue StandardError => e
            logger.error "error sending sms #{e.message}"
          end
        end
      end
    end

    private
    def sms_text(issued)
      %Q{尊敬的爱刷会员，您已获得面额为#{voucher_meta.denomination.to_i/100}元的红包#{issued}张, 可在#{voucher_meta.applicable_store_name}使用。详情请关注微信“aishua2014”【爱刷】}
    end
  end
end
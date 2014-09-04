module External
  class API < Grape::API
    format :json
    formatter :json, Grape::Formatter::Jbuilder
    helpers do
      def logger
        Rails.logger
      end

      def paging_order_info
        {
            page: params[:page] || 1,
            limit: params[:limit] || 20
        }
      end

      def valid_mobile?(mobile)
        mobile = mobile.to_s.strip
        if mobile.length != 11
          false
        else
          mobile =~ /^(((13[0-9]{1})|(15[0-9]{1})|(18[0-9]{1}))+\d{8})$/
        end
      end

      def render_success
        status 200
        {success: 'success'}
      end

      def render_error(status_code = 419, error_msg)
        status status_code
        {error: error_msg}
      end
    end

    rescue_from :all do |e|
      msg = '系统繁忙'
      case e
        when ActiveRecord::RecordInvalid
          status_code = 422
          msg = 'INVALID_INPUT'
        when ActiveRecord::StaleObjectError
          status_code = 409
        when ActiveRecord::RecordNotFound
          msg = 'RECORD_NOT_FOUND'
          status_code = 404
        when StandardError
          status_code = 500
      end
      Rails.logger.error("caught exception: #{e.message}")
      Rails.logger.error("Backtrace:\n\t#{e.backtrace.join("\n\t")}")

      msg ||= e.message
      error_response(status: status_code, message: msg)
    end

    mount External::Member::BankCardsAPI
    mount External::CreditAccountsAPI
    mount External::Merchant::MerchantStoresAPI
    mount External::TransactionLogsAPI
    mount External::VoucherTransactionLogsAPI
    mount External::VouchersAPI

  end
end
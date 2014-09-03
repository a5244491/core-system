module Engine
  module POS
    module PosUtils
      def print_pos_message(msg)
        render_pos_message(200, msg)
      end

      def print_pos_error(msg = nil)
        render_pos_message(419, msg)
      end

      private
      def render_pos_message(status_code, msg)
        error!({screen_msg: msg}, status_code)
      end

      def check_merchant!
        merchant_num = params[:merchant_num]
        raise ArgumentError if merchant_num.nil?
        current_merchant = Merchant::MerchantStore.where(merchant_number: merchant_num).valid.first
        if current_merchant.nil?
          logger.info('transaction failed: merchant is not supported')
          print_pos_error(MessageProperties::MERCHANT_NOT_SUPPORTED)
        end
        request.env['core.current_merchant'] = current_merchant
      end

      def current_merchant
        request.env['core.current_merchant']
      end
    end
  end
end
module Engine
  class API < Grape::API
    CURRENT_CLIENT = 'core.current_client'
    content_type :json, 'application/json;charset=UTF-8'
    format :json
    helpers do
      def logger
        Rails.logger
      end

      def current_client
        request.env[CURRENT_CLIENT]
      end

      def valid_mobile?(mobile)
        mobile.to_s.strip.length == 11
      end
    end

    before do
      account_name = request.env['HTTP_X_ACCOUNT_NAME']
      access_key = request.env['HTTP_X_ACCESS_KEY']
      current_client = System::PlatformAccount.validate(account_name, access_key, System::PlatformAccount::CORE_ENGINE)
      if current_client.nil?
        logger.error "illegal access from #{account_name}"
        error! 'Access Denied', 403
      end
      logger.info "incoming #{request.request_method} request from #{current_client.account_name}, url:#{request.env['rack.mount.prefix']}#{request.path_info}, params:#{params}"
      request.env[CURRENT_CLIENT] = current_client
    end

    mount Engine::POS::PosAPI
  end
end
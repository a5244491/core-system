module Engine
  class API < Grape::API
    CURRENT_CLIENT = 'core.current_client'
    content_type :json, 'application/json;charset=UTF-8'
    format :json
    prefix 'engine'

    before do
      header['Access-Control-Allow-Origin'] = '*'
      header['Access-Control-Request-Method'] = '*'
    end

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

      def authenticate!
        current_client = System::PlatformAccount.validate(params[:api_key], System::PlatformAccount::CORE_ENGINE)
        if current_client.nil?
          logger.error "illegal access from #{request.env['REMOTE_ADDR']}"
          error! 'Access Denied', 403
        end
        logger.info "incoming #{request.request_method} request from #{current_client.account_name}, url:#{request.env['rack.mount.prefix']}#{request.path_info}, params:#{params}"
        request.env[CURRENT_CLIENT] = current_client
      end
    end


    mount Engine::POS::PosAPI
    add_swagger_documentation mount_path: '/api-docs', hide_format: true
  end
end
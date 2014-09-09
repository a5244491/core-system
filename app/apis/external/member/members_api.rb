#encoding:utf-8
class External::Member::MembersAPI < Grape::API
  namespace :members do
    get '/' do
      @credit_accounts = ::Member::CreditAccount.search(params[:query]).result
      @total = @credit_accounts.size
      @credit_accounts = @credit_accounts.paginate(page: current_page, per_page: records_per_page)
      present :total, @total
      present :records, @credit_accounts, with: External::Entities::CreditAccount
    end

    params do
      requires :data, type: Hash do
        requires :mobile
      end
    end
    post '/' do
      if !valid_mobile?(params[:data][:mobile])
        render_error('INVALID_MOBILE')
      else
        begin
          ::Member::CreditAccount.transaction do
            status = params[:data][:status] || ::Member::CreditAccount::ACTIVATED
            referer_account = ::Member::CreditAccount.where(external_id: params[:data][:referer_external_id]).first
            @credit_account = ::Member::IndividualCreditAccount.create_account(mobile: params[:data][:mobile], status: status, referer_account: referer_account)
            @credit_account.update(name: params[:data][:name], address: params[:data][:address])
            if referer_account.instance_of?(::Member::MerchantCreditAccount)
              @credit_account.becomes_member_of(referer_account.merchant_store)
            end
            status 200
            present @credit_account, with: External::Entities::CreditAccount
          end
        rescue ActiveRecord::RecordInvalid => e
          logger.error "failed to create credit account, error: #{e.message}"
          render_error('MOBILE_HAS_BEEN_TAKEN')
        end
      end
    end

    params do
      requires :external_id, type: String
    end
    namespace ':external_id' do
      before do
        @credit_account = Member::CreditAccount.where(external_id: params[:external_id]).first!
      end
      params do
        requires :data, type: Hash
      end
      put '/' do
        mobile = params[:data][:mobile]
        unless mobile.blank? || valid_mobile?(mobile)
          render_error('INVALID_MOBILE')
        else
          begin
            @credit_account.update!(ActionController::Parameters.new(params[:data]).except(:id, :referer_account_id, :external_id).permit!)
            render_success
          rescue ActiveRecord::RecordInvalid => e
            logger.error "failed to update credit account, error: #{e.message}"
            render_error('MOBILE_HAS_BEEN_TAKEN')
          end
        end
      end
    end
  end
end
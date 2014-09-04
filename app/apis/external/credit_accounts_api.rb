#encoding:utf-8
class External::CreditAccountsAPI < Grape::API

  get '/credit_accounts', rabl: '/credit_accounts/index' do
    mobile = params[:mobile]
    external_id = params[:external_id]
    merchant_number = params[:merchant_number]
    @credit_accounts = CoreLib::CreditAccount
    @credit_accounts = @credit_accounts.where(mobile: mobile) unless mobile.blank?
    @credit_accounts = @credit_accounts.where(external_id: external_id) unless external_id.blank?
    unless merchant_number.blank?
      merchant_store = CoreLib::MerchantStore.where(merchant_number: params[:merchant_number]).select('credit_account_id').first
      unless merchant_store.nil?
        @credit_accounts = @credit_accounts.where(id: merchant_store.credit_account_id)
      else
        @credit_accounts = CoreLib::MerchantStore.none
      end
    end
    @credit_accounts = @credit_accounts.where('created_at >= ?', ActiveSupport::TimeZone.new('PRC').parse(params[:start_time])) if not params[:start_time].blank?
    @credit_accounts = @credit_accounts.where('created_at <= ?', ActiveSupport::TimeZone.new('PRC').parse(params[:end_time])) if not params[:end_time].blank?
    unless params[:referer].blank?
      referer_account = CoreLib::CreditAccount.where(external_id: params[:referer]).select('id').first
      @credit_accounts = referer_account.nil? ? CoreLib::CreditAccount.none : @credit_accounts.where(referer_account_id: referer_account.id)
    end
    offset = params[:offset]
    limit = params[:limit]
    @credit_accounts = @credit_accounts.offset(offset.to_i) unless offset.blank?
    @credit_accounts = @credit_accounts.limit(limit.to_i) unless limit.blank?
    @total = limit.blank? ? @credit_accounts.size : @credit_accounts.count
  end


  post '/credit_accounts', rabl: 'credit_accounts/show' do
    raise CreditAccountsException, Messages::MOBILE_INVALID unless valid_mobile?(params[:mobile])
    begin
      referer = params[:referer]
      credit_account = CoreLib::IndividualCreditAccount.new
      credit_account.mobile = params[:mobile]
      credit_account.name = params[:name]
      credit_account.status = params[:status].to_i unless params[:status].blank?
      credit_account.address = params[:address]
      if !referer.blank? && (referer_account = CoreLib::CreditAccount.where(external_id: referer).first)
        credit_account.referer_account = referer_account
        if referer_account.kind_of?(CoreLib::MerchantCreditAccount)
           credit_account.becomes_member_of(referer_account.merchant_store)
        end
      end
      credit_account.save!
    rescue ActiveRecord::RecordInvalid => e
      logger.error "failed to create credit account, error: #{e.message}"
      raise CreditAccountsException, Messages::MOBILE_HAS_BEEN_TAKEN
    end

    @credit_account = credit_account
    status 200
  end


  params do
    requires :external_id, type: String
  end
  put '/credit_accounts' do
    external_id = params[:external_id]
    mobile = params[:mobile]
    raise CreditAccountsException, Messages::ACCOUNT_NOT_EXIST if external_id.blank?
    raise CreditAccountsException, Messages::MOBILE_INVALID unless (mobile.blank? || valid_mobile?(mobile))

    credit_account = CoreLib::CreditAccount.select('id, account_type').where('external_id = ?', external_id).first!
    credit_account = CoreLib::CreditAccount.find_sti_class(credit_account.account_type).find(credit_account.id)
    begin
      credit_account.mobile = mobile unless mobile.blank?
      credit_account.name = params[:name] unless params[:name].nil?
      credit_account.address = params[:address] unless params[:address].nil?
      credit_account.status = params[:status].to_i unless params[:status].blank?
      credit_account.save!
    rescue Exception => e
      logger.error "failed to update credit account, error: #{e.message}"
      raise CreditAccountsException, Messages::MOBILE_HAS_BEEN_TAKEN
    end
    success_response
  end

  params do
    requires :external_id, type: String
  end
  get '/referer_stat', rabl: '/credit_accounts/referer_stat' do
    credit_account = CoreLib::CreditAccount.select('id, account_type').where('external_id = ?', params[:external_id]).first!
    date_conditions = ''
    start_date = params[:start].blank? ? '' : params[:start]
    end_date = params[:end].blank? ? '' : params[:end]
    date_conditions += ' and created_at >= :start ' unless start_date.blank?
    date_conditions += ' and created_at <= :end ' unless end_date.blank?

    sql = "select DATE_FORMAT( c.created_at, '%Y-%m-%d' ) as created_date ,count(*) as stat_count from credit_accounts c where referer_account_id = :referer_account_id #{date_conditions} group by DATE_FORMAT( c.created_at, '%Y-%m-%d') order by DATE_FORMAT( c.created_at, '%Y-%m-%d' ) desc "

    conditions = {:referer_account_id => credit_account.id,
                  :date_conditions => date_conditions,
                  :start => start_date ,
                  :end => end_date
    }
    @credit_accounts = CoreLib::CreditAccount.find_by_sql([sql,conditions])

    @total = CoreLib::CreditAccount.where(referer_account_id: credit_account.id).count

  end


  params do
    requires :external_id, type: String
  end
  get '/active_stat', rabl: '/credit_accounts/referer_stat' do
    credit_account = CoreLib::CreditAccount.select('id, account_type').where('external_id = ?', params[:external_id]).first!
    merchant_sotre_id = CoreLib::MerchantStore.select('id').where('credit_account_id = ?', credit_account.id).first!
    date_conditions = ''
    #merchant_sotre_id = params[:merchant_sotre_id].blank? ? '' : params[:merchant_sotre_id]
    start_date = params[:start].blank? ? '' : params[:start]
    end_date = params[:end].blank? ? '' : params[:end]
    date_conditions += ' and t.transaction_datetime >= :start ' unless start_date.blank?
    date_conditions += ' and t.transaction_datetime <= :end ' unless end_date.blank?
    #
    sql = "select DATE_FORMAT( t.transaction_datetime, '%Y-%m-%d' ) as created_date,
            count(DISTINCT t.credit_account_id) as stat_count
            from transaction_logs t
            where t.merchant_store_id = :merchant_sotre_id
                  and t.log_type=#{CoreLib::TransactionLog::PRIMARY}
                  #{date_conditions}
                  group by created_date
                  order by created_date desc "

    conditions = {:merchant_sotre_id => merchant_sotre_id,
                  :referer_account_id => credit_account.id,
                  :date_conditions => date_conditions,
                  :start => start_date ,
                  :end => end_date
    }
    @credit_accounts = CoreLib::TransactionLog.find_by_sql([sql,conditions])
    @total = CoreLib::CreditAccount.where(referer_account_id: credit_account.id).count
  end

  params do
    requires :external_id, type: String
  end
  get '/transaction_stat', rabl: '/credit_accounts/transaction_stat' do
    credit_account = CoreLib::CreditAccount.select('id, account_type').where('external_id = ?', params[:external_id]).first!
    merchant_store_id = CoreLib::MerchantStore.select('id').where('credit_account_id = ?', credit_account.id).first!
    member_sql = 'select t.credit_account_id, t.credit_account_external_id,t.customer_name,t.mobile,sum(actual_money_amount) as money_amount_sum from transaction_logs t where credit_account_id is not null and t.log_type = 1 and merchant_store_id = :merchant_store_id group by t.credit_account_id order by money_amount_sum desc limit 10 '
    @member_ranking = CoreLib::TransactionLog.find_by_sql([member_sql,{:merchant_store_id => merchant_store_id}])
  end


  params do
    requires :external_id, type: String
  end
  get '/member_total_stat', rabl: '/credit_accounts/referer_stat' do
    credit_account = CoreLib::CreditAccount.select('id, account_type').where('external_id = ?', params[:external_id]).first!
    end_date = params[:end].blank? ? '' : ActiveSupport::TimeZone.new('PRC').parse(params[:end])
    member_sql = "select
                    DATE_FORMAT(:end, '%Y-%m-%d' ) as created_date,
                    count(DISTINCT c.id) as stat_count
                  from
                    credit_accounts c
                  where
                    c.referer_account_id = :referer_account_id
                    and c.created_at <= :end "
    p member_sql
    conditions = {:referer_account_id => credit_account.id,
                  :end => end_date
    }
    @credit_accounts = CoreLib::CreditAccount.find_by_sql([member_sql, conditions])
  end
end
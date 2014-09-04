class External::TransactionLogsAPI < Grape::API
  params do
    requires :credit_account_external_id, type: String
  end
  get '/transaction_logs', rabl: '/transaction_logs/index' do
    credit_account = CoreLib::CreditAccount.where(:external_id => params[:credit_account_external_id]).first!
    if credit_account.is_a? CoreLib::IndividualCreditAccount
      logs = CoreLib::TransactionLog.where(:credit_account_id => credit_account.id)
    else
      logs = CoreLib::TransactionLog.where(:merchant_store_id => credit_account.merchant_store.id)
    end
    logs = logs.where(log_type: params[:log_type].to_i) unless params[:log_type].blank?
    if !params[:payment_media_id].blank? && (payment_media = CoreLib::PaymentMedia.select('media_num').where({:id => params[:payment_media_id], :credit_account_id => credit_account.id}).first)
      logs = logs.where('media_num = ?', payment_media.media_num)
    end
    logs = logs.where('transaction_datetime >= ?', ActiveSupport::TimeZone.new('PRC').parse(params[:start])) unless params[:start].blank?
    logs = logs.where('transaction_datetime <= ?', ActiveSupport::TimeZone.new('PRC').parse(params[:end])) unless params[:end].blank?
    logs = logs.where('terminal_num = ?', params[:terminal_num]) unless params[:terminal_num].blank?
    logs = logs.where('sequence_number = ?', params[:sequence_number]) unless params[:sequence_number].blank?
    logs = logs.where('transaction_type = ?', params[:transaction_type]) unless params[:transaction_type].blank?
    logs = logs.where('status = ?', params[:status]) unless params[:status].blank?
    logs = logs.where('media_num like ?', "%#{params[:media_num_suffix]}") unless params[:media_num_suffix].blank?
    logs = logs.where('merchant_name like ?', "%#{params[:merchant_name]}%") unless params[:merchant_name].blank?
    logs = logs.where('matched_bank like ?', "%#{params[:matched_bank]}%") unless params[:matched_bank].blank?
    logs = logs.where('checked = ?', params[:checked]) unless params[:checked].blank?
    unless (voucher_used = params[:voucher_used]).blank?
      if voucher_used.to_s == 'true'
        logs = logs.where('voucher_used_count > 0')
      else
        logs = logs.where('voucher_used_count = 0')
      end
    end
    @sum = {}
    if params[:sum].kind_of?(Array)
      params[:sum].each do |p|
        @sum.store(p, logs.calculate(:sum, p.to_sym))
      end
    end
    @transaction_logs_count = logs.select('id').count
    logs = logs.offset(params[:offset].to_i) unless params[:offset].blank?
    logs = logs.limit(params[:limit].to_i) unless params[:limit].blank?
    @transaction_logs = logs.order('transaction_datetime desc, id desc')

  end

  params do
    requires :merchant_credit_account_external_id, type: String
    requires :checked, type: Integer
    requires :id, type: String
  end
  put '/transaction_logs' do
    credit_account = CoreLib::CreditAccount.where(:external_id => params[:merchant_credit_account_external_id]).first!
    if credit_account.is_a? CoreLib::MerchantCreditAccount
      CoreLib::TransactionLog.where(merchant_store_id: credit_account.merchant_store.id, id: params[:id]).update_all(checked: params[:checked])
      success_response
    else
      error_response('无法找到该条交易记录')
    end
  end

  params do
    requires :merchant_credit_account_external_id, type: String
  end
  get '/transaction_logs/stat_member', rabl: '/transaction_logs/stat_member' do
    credit_account = CoreLib::CreditAccount.where(:external_id => params[:merchant_credit_account_external_id]).first!
    if credit_account.is_a? CoreLib::MerchantCreditAccount
      str_conditions = ''
      start_date = params[:start].blank? ? '' : ActiveSupport::TimeZone.new('PRC').parse(params[:start])
      end_date = params[:end].blank? ? '' : ActiveSupport::TimeZone.new('PRC').parse(params[:end])

      str_conditions += ' and transaction_datetime >= :start ' unless start_date.blank?
      str_conditions += ' and transaction_datetime <= :end ' unless end_date.blank?
      str_conditions += " and credit_account_id = '#{params[:credit_account_id]}' " unless params[:credit_account_id].blank?
      str_conditions += " and mobile like '%#{params[:mobile]}%' " unless params[:mobile].blank?
      str_conditions += " and media_num like '%#{params[:media_num]}%' " unless params[:media_num].blank?

      offset = params[:offset].blank? ? 0 : params[:offset].to_i
      limit = params[:limit].blank? ? 2 : params[:limit].to_i

      sql = "SELECT
              credit_account_id as member_id,
              case when referer_id = #{credit_account.id} then '本店会员'
                      when referer_id is not null then '其他会员'
                      else '非注册用户'
              end as member_bz,
              max(id),
              max(transaction_datetime) as max_date,
              credit_account_id,
              sum(actual_money_amount) as total_amount,
              count(id) as total_count,
              media_num,
              matched_bank,
              mobile,
              substring_index(group_concat(actual_money_amount order by transaction_datetime desc), ',', 1) as last_money_amount
            from transaction_logs
            where merchant_store_id= :merchant_store_id
              and credit_account_id is not null
              and log_type=#{CoreLib::TransactionLog::PRIMARY}
      #{str_conditions}  GROUP BY credit_account_id "

      conditions = {:merchant_store_id => credit_account.merchant_store.id,
                    :str_conditions => str_conditions,
                    :start => start_date,
                    :end => end_date,
                    :limit => limit, :offset => offset}
      @logs_count = CoreLib::TransactionLog.find_by_sql([sql, conditions]).count
      @logs = CoreLib::TransactionLog.find_by_sql([sql << ' limit :limit offset :offset ', conditions])
    else
      error_response('无法找到该条交易记录')
    end
  end


  params do
    requires :merchant_credit_account_external_id, type: String
  end
  get '/transaction_logs/active_detail', rabl: '/transaction_logs/stat_member' do
    credit_account = CoreLib::CreditAccount.where(:external_id => params[:merchant_credit_account_external_id]).first!
    if credit_account.is_a? CoreLib::MerchantCreditAccount
      date_conditions = ''
      start_date = params[:start].blank? ? '' : ActiveSupport::TimeZone.new('PRC').parse(params[:start])
      end_date = params[:end].blank? ? '' : ActiveSupport::TimeZone.new('PRC').parse(params[:end])
      if !start_date.blank?
        date_conditions += ' and transaction_datetime >= :start '
      end

      if !end_date.blank?
        date_conditions += ' and transaction_datetime < :end '
      end

      offset = params[:offset].blank? ? 0 : params[:offset].to_i
      limit = params[:limit].blank? ? 2 : params[:limit].to_i

      sql = "SELECT max(id) as id,
            max(transaction_datetime) as max_date,
            case when referer_id = #{credit_account.id} then '本店会员'
              when referer_id is not null then '其他会员'
              else '非注册用户'
            end as member_bz,
            referer_id,
            credit_account_id,
            media_num,
            matched_bank,
            sum(actual_money_amount) as total_amount,
            count(id) as total_count,
            mobile,
            substring_index(group_concat(actual_money_amount order by transaction_datetime desc), ',', 1)
            as last_money_amount
            from transaction_logs
            where merchant_store_id= :merchant_store_id
            and log_type=#{CoreLib::TransactionLog::PRIMARY}
      #{date_conditions}  GROUP BY credit_account_id "

      conditions = {:merchant_store_id => credit_account.merchant_store.id,
                    :date_conditions => date_conditions,
                    :start => start_date,
                    :end => end_date,
                    :limit => limit, :offset => offset}
      @logs_count = CoreLib::TransactionLog.find_by_sql([sql, conditions]).count
      @logs = CoreLib::TransactionLog.find_by_sql([sql << ' limit :limit offset :offset ', conditions])
    else
      error_response('无法找到该条交易记录')
    end
  end


  params do
    requires :merchant_credit_account_external_id, type: String
  end
  get '/transaction_logs/new_detail', rabl: '/transaction_logs/stat_member' do
    credit_account = CoreLib::CreditAccount.where(:external_id => params[:merchant_credit_account_external_id]).first!
    if credit_account.is_a? CoreLib::MerchantCreditAccount
      date_conditions = ''
      start_date = params[:start].blank? ? '' : ActiveSupport::TimeZone.new('PRC').parse(params[:start])
      end_date = params[:end].blank? ? '' : ActiveSupport::TimeZone.new('PRC').parse(params[:end])
      if !start_date.blank?
        date_conditions += ' and c.created_at >= :start '
      end

      if !end_date.blank?
        date_conditions += ' and c.created_at < :end '
      end

      offset = params[:offset].blank? ? 0 : params[:offset].to_i
      limit = params[:limit].blank? ? 2 : params[:limit].to_i
      sql = "SELECT
              c.id as member_id,
              '本店会员' as member_bz,
              COUNT(t.id) AS stat_count,
              t.credit_account_id,
              t.media_num,
              t.matched_bank,
              sum(t.actual_money_amount) AS total_amount,
              c.mobile,
              substring_index(
                group_concat(
                  t.actual_money_amount
                  ORDER BY
                    t.transaction_datetime DESC
                ),
                ',',
                1
              ) AS last_money_amount
            FROM
              credit_accounts c
            LEFT JOIN transaction_logs t ON (
              t.credit_account_id = c.id
              AND t.merchant_store_id = :merchant_store_id
              AND t.log_type=#{CoreLib::TransactionLog::PRIMARY}
            )
            WHERE
              c.referer_account_id = #{credit_account.id}
      #{date_conditions}
            GROUP BY
              c.id"

      conditions = {:merchant_store_id => credit_account.merchant_store.id,

                    :date_conditions => date_conditions,
                    :start => start_date,
                    :end => end_date,
                    :limit => limit, :offset => offset}
      @logs_count = CoreLib::TransactionLog.find_by_sql([sql, conditions]).count
      @logs = CoreLib::TransactionLog.find_by_sql([sql << ' limit :limit offset :offset ', conditions])
    else
      error_response('无法找到该条交易记录')
    end
  end


  params do
    requires :merchant_credit_account_external_id, type: String
  end
  get '/transaction_logs/single_member', rabl: '/transaction_logs/single_member' do
    credit_account = CoreLib::CreditAccount.where(:external_id => params[:merchant_credit_account_external_id]).first!
    date_conditions = ''
    start_date = params[:start].blank? ? '' : ActiveSupport::TimeZone.new('PRC').parse(params[:start])
    end_date = params[:end].blank? ? '' : ActiveSupport::TimeZone.new('PRC').parse(params[:end])
    if !start_date.blank?
      date_conditions += ' and c.created_at >= :start '
    end

    if !end_date.blank?
      date_conditions += ' and c.created_at <= :end '
    end
    member_id = params[:member_id]
    offset = params[:offset].blank? ? 0 : params[:offset].to_i
    limit = params[:limit].blank? ? 2 : params[:limit].to_i
    sql = "SELECT c.id as member_id,
            case when c.referer_account_id = #{credit_account.id} then '本店会员'
                 when c.referer_account_id is not null then '其他会员'
                else '非注册用户'
            end as member_bz,
            count(t.id) as total_count,
            c.referer_account_id as referer_id,
            t.credit_account_id as credit_account_id,
	          t.media_num,
            t.matched_bank,
            sum(t.actual_money_amount) as total_amount,

            t.mobile,
            substring_index(group_concat(t.actual_money_amount order by t.transaction_datetime desc), ',', 1) as last_money_amount
            from credit_accounts c
							  LEFT JOIN transaction_logs t ON (
                t.credit_account_id = c.id
                AND t.log_type = #{CoreLib::TransactionLog::PRIMARY}
            )
            where
            c.id = #{member_id}

    #{date_conditions}  GROUP BY credit_account_id "

    conditions = {:merchant_store_id => credit_account.merchant_store.id,
                  :date_conditions => date_conditions,
                  :start => start_date,
                  :end => end_date,
                  :limit => limit, :offset => offset}

    @logs_count = CoreLib::TransactionLog.find_by_sql([sql, conditions]).count
    @logs = CoreLib::TransactionLog.find_by_sql([sql << ' limit :limit offset :offset ', conditions])

  end

  params do
    requires :merchant_credit_account_external_id, type: String
  end
  get '/transaction_logs/stat', rabl: '/transaction_logs/stat' do
    credit_account = CoreLib::CreditAccount.where(:external_id => params[:merchant_credit_account_external_id]).first!
    date_conditions = ''
    start_date = params[:start].blank? ? '' : ActiveSupport::TimeZone.new('PRC').parse(params[:start])
    end_date = params[:end].blank? ? '' : ActiveSupport::TimeZone.new('PRC').parse(params[:end])
    date_conditions += ' and created_at >= :start ' unless start_date.blank?
    date_conditions += ' and created_at <= :end ' unless end_date.blank?

    sql = "SELECT sum(actual_money_amount) as total_amount , count(*) as transaction_count from transaction_logs where log_type = #{CoreLib::TransactionLog::PRIMARY} and merchant_store_id = :merchant_store_id  #{date_conditions}  "

    conditions = {:merchant_store_id => credit_account.merchant_store.id,
                  :date_conditions => date_conditions,
                  :start => start_date,:end => end_date}

    @log = CoreLib::TransactionLog.find_by_sql([sql, conditions])
  end

  params do
    requires :merchant_credit_account_external_id, type: String
  end

  get '/transaction_logs/stat_amount', rabl: '/transaction_logs/stat_amount' do
    credit_account = CoreLib::CreditAccount.where(:external_id => params[:merchant_credit_account_external_id]).first!
    date_conditions = ''
    start_date = params[:start_date].blank? ? '' : ActiveSupport::TimeZone.new('PRC').parse(params[:start_date])
    end_date = params[:end_date].blank? ? '' : ActiveSupport::TimeZone.new('PRC').parse(params[:end_date])
    date_conditions += ' and created_at >= :start_date ' unless start_date.blank?
    date_conditions += ' and created_at <= :end_date ' unless end_date.blank?

    sql = "SELECT DATE_FORMAT( created_at, '%Y-%m-%d' ) as created_date, sum(actual_money_amount) as stat_count from transaction_logs where log_type = #{CoreLib::TransactionLog::PRIMARY} and merchant_store_id = :merchant_store_id  #{date_conditions} group by DATE_FORMAT( created_at, '%Y-%m-%d' ) order by DATE_FORMAT( created_at, '%Y-%m-%d' ) asc "

    conditions = {:merchant_store_id => credit_account.merchant_store.id,
                  :date_conditions => date_conditions,
                  :start_date => start_date,:end_date => end_date}

    @logs = CoreLib::TransactionLog.find_by_sql([sql, conditions])
  end


  params do
    requires :external_id, type: String
  end

  get '/transaction_logs/stat_consumer_ratio', rabl: '/transaction_logs/stat_amount' do
    credit_account = CoreLib::CreditAccount.where(:external_id => params[:external_id]).first!
    date_conditions = ''
    start_date = params[:start].blank? ? '' : ActiveSupport::TimeZone.new('PRC').parse(params[:start])
    end_date = params[:end].blank? ? '' : ActiveSupport::TimeZone.new('PRC').parse(params[:end])
    date_conditions += ' and created_at >= :start ' unless start_date.blank?
    date_conditions += ' and created_at <= :end ' unless end_date.blank?

    sql = "select count(distinct credit_account_id ) as total_amount,
               referer_id,
               case when referer_id = :referer_id then '本店会员'
                 when referer_id is not null then '其他会员'
                 else '非注册用户'
               end as created_date
          from transaction_logs
          where merchant_store_id = :merchant_store_id
          and log_type = #{CoreLib::TransactionLog::PRIMARY}
          #{date_conditions}
          group by created_date"

    conditions = {:merchant_store_id => credit_account.merchant_store.id,
                  :referer_id => credit_account.id,
                  :date_conditions => date_conditions,
                  :start => start_date,
                  :end => end_date}

    @logs = CoreLib::TransactionLog.find_by_sql([sql, conditions])
  end

  params do
    requires :merchant_credit_account_external_id, type: String
  end
  get '/transaction_logs/stat_amount_by_transaction_type', rabl: '/transaction_logs/stat_by_transaction_type'  do
    credit_account = CoreLib::CreditAccount.where(:external_id => params[:merchant_credit_account_external_id]).first!
    sql = "SELECT transaction_type , sum(actual_money_amount) as total_amount from transaction_logs where log_type = #{CoreLib::TransactionLog::PRIMARY} and merchant_store_id = :merchant_store_id group by transaction_type "
    @logs = CoreLib::TransactionLog.find_by_sql([sql, {:merchant_store_id => credit_account.merchant_store.id}])
  end

end
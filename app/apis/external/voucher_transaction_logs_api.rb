#encoding:utf-8
class External::VoucherTransactionLogsAPI < Grape::API
  params do
    requires :credit_account_external_id, type: String
  end
  get '/voucher_transaction_logs', rabl: '/voucher_transaction_logs/index' do
    credit_account = CoreLib::CreditAccount.where(:external_id => params[:credit_account_external_id]).first!
    if credit_account.is_a? CoreLib::IndividualCreditAccount
      logs = CoreLib::VoucherTransactionLog.where(:credit_account_id => credit_account.id)
    else
      logs = CoreLib::VoucherTransactionLog.where(:merchant_store_id => credit_account.merchant_store.id)
    end

    unless params[:issuer_type].blank?
      logs = logs.where(:issuer_type => params[:issuer_type])
      unless params[:issuer_identifier].blank?
        logs = logs.where(:issuer_identifier => params[:issuer_identifier])
      end
      unless params[:issuer_name].blank?
        logs = logs.where(:issuer_name => params[:issuer_name])
      end
    end

    unless params[:settler_type].blank?
      logs = logs.where(:settler_type => params[:settler_type])
      unless params[:settler_identifier].blank?
        logs = logs.where(:settler_identifier => params[:settler_identifier])
      end
      unless params[:settler_name].blank?
        logs = logs.where(:settler_name => params[:settler_name])
      end
    end
    logs = logs.where(:transaction_type => params[:transaction_type]) unless params[:transaction_type].blank?
    logs = logs.where(:issue_event => params[:issue_event]) unless params[:issue_event].blank?
    logs = logs.where('transaction_datetime >= ?', ActiveSupport::TimeZone.new('PRC').parse(params[:start])) unless params[:start].blank?
    logs = logs.where('transaction_datetime <= ?', ActiveSupport::TimeZone.new('PRC').parse(params[:end])) unless params[:end].blank?
    logs = logs.where('checked = ?', params[:checked]) unless params[:checked].blank?

    @sum = {}
    if params[:sum].kind_of?(Array)
      params[:sum].each do |p|
        @sum.store(p, logs.calculate(:sum, p.to_sym))
      end
    end
    @voucher_transaction_logs_count = logs.select('id').count
    logs = logs.offset(params[:offset].to_i) unless params[:offset].blank?
    logs = logs.limit(params[:limit].to_i) unless params[:limit].blank?
    @voucher_transaction_logs = logs.order('transaction_datetime desc, id desc')

  end

  params do
    requires :merchant_credit_account_external_id, type: String
    requires :checked, type: Integer
    requires :id, type: String
  end
  put '/voucher_transaction_logs' do
    credit_account = CoreLib::CreditAccount.where(:external_id => params[:merchant_credit_account_external_id]).first!
    if credit_account.is_a? CoreLib::MerchantCreditAccount
      CoreLib::VoucherTransactionLog.where(:merchant_store_id => credit_account.merchant_store.id, :id => params[:id]).update_all(checked: params[:checked])
      success_response
    else
      error_response('无法找到该条红包交易记录')
    end
  end


  params do
    requires :merchant_credit_account_external_id, type: String
    requires :transaction_type, type: String
  end
  get '/voucher_transaction_logs/stat_voucher_amount_by_transaction_type', rabl: '/voucher_transaction_logs/voucher_amount'  do
    transaction_type = params[:transaction_type]
    credit_account = CoreLib::CreditAccount.where(:external_id => params[:merchant_credit_account_external_id]).first!
    sql = 'SELECT
        id
    FROM
        voucher_transaction_logs
    WHERE
        merchant_store_id = :merchant_store_id
            AND transaction_type = :transaction_type'
    #@logs = CoreLib::TransactionLog.find_by_sql([sql, {:merchant_store_id => credit_account.merchant_store.id}])
    @logs_count = CoreLib::VoucherTransactionLog.find_by_sql([sql, {:merchant_store_id => credit_account.merchant_store.id, :transaction_type => transaction_type}]).count
  end

end
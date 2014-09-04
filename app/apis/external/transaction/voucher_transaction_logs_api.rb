module External::Transaction
  class VoucherTransactionLogsAPI < Grape::API
    get '/voucher_transaction_logs', jbuilder: 'external/transaction/voucher_transaction_logs/index' do
      unless params[:query].blank? || params[:query][:credit_account_external_id_eq].blank?
        account = Member::IndividualCreditAccount.where(external_id: params[:query].delete(:credit_account_external_id_eq)).first
        credit_account_id = account.nil? ? -1 : account.id
        params[:query][:credit_account_id_eq] = credit_account_id
      end

      @voucher_transaction_logs = Trade::VoucherTransactionLog.search(params[:query]).result
      if params[:sum].kind_of?(Array)
        params[:sum].each do |field|
          @sum.store(field, @voucher_transaction_logs.calculate(:sum, field.to_sym))
        end
      end
      @total = @voucher_transaction_logs.size
      @voucher_transaction_logs = @voucher_transaction_logs.order(transaction_datetime: :desc, id: :desc).paginate(page: current_page, per_page: records_per_page)
    end

    # params do
    #   requires :merchant_credit_account_external_id, type: String
    #   requires :checked, type: Integer
    #   requires :id, type: String
    # end
    # put '/voucher_transaction_logs' do
    #   credit_account = CoreLib::CreditAccount.where(:external_id => params[:merchant_credit_account_external_id]).first!
    #   if credit_account.is_a? CoreLib::MerchantCreditAccount
    #     CoreLib::VoucherTransactionLog.where(:merchant_store_id => credit_account.merchant_store.id, :id => params[:id]).update_all(checked: params[:checked])
    #     success_response
    #   else
    #     error_response('无法找到该条红包交易记录')
    #   end
    # end
    #
    #
    # params do
    #   requires :merchant_credit_account_external_id, type: String
    #   requires :transaction_type, type: String
    # end
    # get '/voucher_transaction_logs/stat_voucher_amount_by_transaction_type', rabl: '/voucher_transaction_logs/voucher_amount' do
    #   transaction_type = params[:transaction_type]
    #   credit_account = CoreLib::CreditAccount.where(:external_id => params[:merchant_credit_account_external_id]).first!
    #   sql = 'SELECT
    #     id
    # FROM
    #     voucher_transaction_logs
    # WHERE
    #     merchant_store_id = :merchant_store_id
    #         AND transaction_type = :transaction_type'
    #   #@logs = CoreLib::TransactionLog.find_by_sql([sql, {:merchant_store_id => credit_account.merchant_store.id}])
    #   @logs_count = CoreLib::VoucherTransactionLog.find_by_sql([sql, {:merchant_store_id => credit_account.merchant_store.id, :transaction_type => transaction_type}]).count
    # end
  end
end
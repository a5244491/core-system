module External::Transaction
  class VoucherTransactionLogsAPI < Grape::API
    get '/voucher_transaction_logs' do
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
      present :total, @total
      present :records, @voucher_transaction_logs, with: External::Entities::VoucherTransactionLog
      present :sum, @sum
    end
  end
end
module External
  module Transaction
    class TransactionLogsAPI < Grape::API
      get '/transaction_logs' do
        @transaction_logs = Trade::TransactionLog.search(params[:query]).result
        if params[:sum].kind_of?(Array)
          params[:sum].each do |field|
            @sum.store(field, @transaction_logs.calculate(:sum, field.to_sym))
          end
        end
        @total = @transaction_logs.size
        @transaction_logs = @transaction_logs.order(transaction_datetime: :desc, id: :desc).paginate(page: current_page, per_page: records_per_page)
        present :total, @total
        present :sum, @sum
        present :records, @transaction_logs, with: External::Entities::TransactionLog
      end
    end
  end
end
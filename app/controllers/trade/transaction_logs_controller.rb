class Trade::TransactionLogsController < ApplicationController
  before_action :set_trade_transaction_log, only: [:show]

  # GET /trade/transaction_logs
  # GET /trade/transaction_logs.json
  def index
    @q =  Trade::TransactionLog.search(params[:q])
    @trade_transaction_logs = @q.result.order(created_at: :desc).paginate(page: @page, per_page: @limit)
  end

  # GET /trade/transaction_logs/1
  # GET /trade/transaction_logs/1.json
  def show
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_trade_transaction_log
      @trade_transaction_log = Trade::TransactionLog.where(id: params[:id]).first!
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def trade_transaction_log_params
      params[:trade_transaction_log]
    end
end

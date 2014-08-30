class Trade::TransactionLogsController < ApplicationController
  before_action :set_trade_transaction_log, only: [:show]

  # GET /trade/transaction_logs
  # GET /trade/transaction_logs.json
  def index
    @q = Trade::TransactionLog.search(tweak_search_params(params))
    @trade_transaction_logs = @q.result
    @money_amount_sum = @trade_transaction_logs.sum(:money_amount)
    @actual_money_amount_sum= @trade_transaction_logs.sum(:actual_money_amount)
    @credit_delta_sum= @trade_transaction_logs.sum(:credit_delta)
    @merchant_amount_sum =@trade_transaction_logs.sum(:merchant_amount)
    @transaction_count = @trade_transaction_logs.primary_log.count
    @trade_transaction_logs = @trade_transaction_logs.order(transaction_datetime: :desc).paginate(page: @page, per_page: @limit)
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

  def tweak_search_params(params)
    if params[:member_transaction] == 'true'
      params[:q][:credit_account_id_present] = '1'
    elsif params[:member_transaction] == 'false'
      params[:q][:credit_account_id_blank] = '1'
    end
    if params[:used_voucher] == 'true'
      params[:q][:voucher_used_count_gt] = 0
    elsif params[:used_voucher] == 'false'
      params[:q][:voucher_used_count_lteq] = 0
    end
    params[:q]
  end
end

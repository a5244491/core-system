class Trade::VoucherTransactionLogsController < ApplicationController
  before_action :set_trade_voucher_transaction_log, only: [:show]

  def index
    @q = Trade::VoucherTransactionLog.search(tweak_search_params(params))
    @trade_voucher_transaction_logs = @q.result.order(transaction_datetime: :desc).paginate(page: @page, per_page: @limit)
  end

  def show
  end

  private
  def set_trade_voucher_transaction_log
    @trade_voucher_transaction_log = Trade::VoucherTransactionLog.where(id: params[:id]).first!
  end

  def tweak_search_params(params)
    params[:q]
  end
end

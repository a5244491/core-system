class Trade::TransactionsController < ApplicationController
  authorize_resource class: 'Trade::Transaction'

  before_action :set_trade_transaction, only: [:show]

  def index
    @q = Trade::Transaction.search(params[:q])
    @trade_transactions = @q.result.order(created_at: :desc).paginate(page: @page, per_page: @limit)
  end

  def show
  end

  private
    def set_trade_transaction
      @trade_transaction = Trade::Transaction.find(params[:id])
    end
end

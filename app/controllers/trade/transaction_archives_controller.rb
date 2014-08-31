class Trade::TransactionArchivesController < ApplicationController
  authorize_resource class: 'Trade::TransactionArchive'
  before_action :set_trade_transaction_archive, only: [:show]

  def index
    @q = Trade::TransactionArchive.search(params[:q])
    @trade_transaction_archives = @q.result.order(created_at: :desc).paginate(page: @page, per_page: @limit)
  end

  def show
  end

  private
  def set_trade_transaction_archive
    @trade_transaction_archive = Trade::TransactionArchive.find(params[:id])
  end
end

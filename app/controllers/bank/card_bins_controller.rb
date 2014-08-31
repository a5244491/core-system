class Bank::CardBinsController < ApplicationController
  authorize_resource class: 'Bank::CardBin'
  before_action :set_bank_card_bin, only: [:edit, :update, :destroy]

  # GET /bank/card_bins
  # GET /bank/card_bins.json
  def index
    @q = Bank::CardBin.search(params[:q])
    @bank_card_bins = @q.result.order(created_at: :desc).paginate(page: @page, per_page: @limit)
  end

  def match
    @bank_card_bins = Array.new
    unless params[:bank_card_num].blank?
      match_card_bin = Bank::CardBin.card_bin_match params[:bank_card_num]
      @bank_card_bins << match_card_bin unless match_card_bin.nil?
    end
    render :index
  end

  # GET /bank/card_bins/new
  def new
    @bank_card_bin = Bank::CardBin.new
  end

  # GET /bank/card_bins/1/edit
  def edit
  end

  # POST /bank/card_bins
  # POST /bank/card_bins.json
  def create
    @bank_card_bin = Bank::CardBin.new(bank_card_bin_params)
    if @bank_card_bin.save
      record_activities('创建', '卡bin', @bank_card_bin.bank_bin)
      flash[:success] = '创建卡bin成功'
      redirect_to bank_card_bins_path
    else
      flash[:error] = "创建失败: #{@bank_card_bin.errors.full_message}"
      render :new
    end
  end

  # PATCH/PUT /bank/card_bins/1
  # PATCH/PUT /bank/card_bins/1.json
  def update
    if @bank_card_bin.update(bank_card_bin_params)
      record_activities('修改', '卡bin', @bank_card_bin.bank_bin)
      flash[:success] = '修改卡bin成功'
      redirect_to bank_card_bins_path
    else
      flash[:error] = "修改失败: #{@bank_card_bin.errors.full_message}"
      render :edit
    end
  end

  # DELETE /bank/card_bins/1
  # DELETE /bank/card_bins/1.json
  def destroy
    if @bank_card_bin.destroy
      record_activities('删除', '卡bin', @bank_card_bin.bank_bin)
      flash[:success] = '删除卡bin成功'
    else
      flash[:error] = "删除失败: #{@bank_card_bin.errors.full_message}"
    end
    redirect_to request.referer
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_bank_card_bin
    @bank_card_bin = Bank::CardBin.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def bank_card_bin_params
    params[:bank_card_bin].except(:id).permit!
  end
end

class Merchant::VoucherActionsController < ApplicationController
  before_action :set_marketing_rule
  authorize_resource class: 'Merchant::MarketingRule'

  def create
    @merchant_voucher_action = Merchant::VoucherAction.new(merchant_voucher_action_params.merge(marketing_rule: @marketing_rule))

    if @merchant_voucher_action.save
      flash[:success] = '添加成功'
    else
      flash[:error] = "添加失败: #{@merchant_voucher_action.errors.full_messages}"
    end
    redirect_to request.referer
  end

  private
  # Never trust parameters from the scary internet, only allow the white list through.
  def merchant_voucher_action_params
    params[:merchant_voucher_action].except(:id).permit!
  end

  def set_marketing_rule
    @marketing_rule = Merchant::MarketingRule.find(params[:marketing_rule_id])
  end
end

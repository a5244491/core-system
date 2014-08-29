class Merchant::NonePaymentPlansController < ApplicationController
  before_action :set_merchant_store
  before_action :set_merchant_bank_discount

  def edit
    @form = Merchant::NonePaymentPlanForm.new(@none_payment_plan)
  end

  def update
    unless @none_payment_plan.may_edit?
      flash[:error] = '当前支付计划不可修改'
      render :edit and return
    end
    @form = Merchant::NonePaymentPlanForm.new(@none_payment_plan)
    if @form.validate(merchant_none_payment_plan_params)
      if @form.save
        flash[:success] = '修改成功'
        record_activities('修改', '支付计划', "#{@merchant_store.name} - #{@form.model.id}")
        redirect_to merchant_merchant_store_payment_plans_path
      else
        flash[:error] = "创建失败: #{@form.model.errors.full_messages}"
        render :edit
      end
    else
      flash[:error] = "创建失败: #{@form.errors.full_messages}"
      render :edit
    end
  end

  private
  def set_merchant_bank_discount
    @none_payment_plan = Pay::NonePaymentPlan.where(merchant_store: @merchant_store, id: params[:id]).first
  end

  def set_merchant_store
    @merchant_store = Merchant::MerchantStore.find(params[:merchant_store_id])
  end

  def merchant_none_payment_plan_params
    params[:merchant_none_payment_plan].except(:status, :plan_type, :id).permit!
  end
end

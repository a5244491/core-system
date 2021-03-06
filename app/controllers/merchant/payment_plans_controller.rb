class Merchant::PaymentPlansController < Merchant::MerchantStoreResourcesBasicController
  authorize_resource class: 'Pay::PaymentPlan'
  before_action :set_payment_plan, only: [:disable, :enable, :destroy]
  authorize_resource class: 'Pay::PaymentPlan'

  # GET /merchant/payment_plans
  def index
    @none_payment_plan = Pay::NonePaymentPlan.where(merchant_store: @merchant_store).first
    @bank_discount_plans = Pay::BankDiscount.where(merchant_store: @merchant_store)
    @credit_back_plans = Pay::CreditBack.where(merchant_store: @merchant_store)
  end

  def enable
    if @payment_plan.may_enable?
      begin
        @payment_plan.enable
        record_activities('生效', '支付计划', "#{@merchant_store.name} - ##{@payment_plan.id}")
        flash[:success] = '操作成功'
      rescue StandardError => e
        flash[:error] = "操作失败: #{e.message}"
      end
    else
      flash[:error] = '操作失败: 当前计划不可生效'
    end
    redirect_to request.referrer
  end

  def disable
    if @payment_plan.may_disable?
      begin
        @payment_plan.disable
        record_activities('失效', '支付计划', "#{@merchant_store.name} - ##{@payment_plan.id}")
        flash[:success] = '操作成功'
      rescue StandardError => e
        flash[:error] = "操作失败: #{e.message}"
      end
    else
      flash[:error] = '操作失败: 当前计划不可失效'
    end
    redirect_to request.referrer
  end

  def destroy
    unless @payment_plan.may_destroy?
      flash[:error] = Tips::MERCHANT_CAN_NOT_DELETE
    else
      if @payment_plan.destroy
        record_activities('删除', '支付计划',  "#{@merchant_store.name} - ##{@payment_plan.id}")
        flash[:success] = Tips::DELETE_SUCCESS
      else
        flash[:error] = Tips::DELETE_ERROR
      end
    end
    redirect_to request.referrer
  end

  private
  def set_payment_plan
    @payment_plan = @merchant_store.payment_plans.find(params[:payment_plan_id] || params[:id])
  end
end

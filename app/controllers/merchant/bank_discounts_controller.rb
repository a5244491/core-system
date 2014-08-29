class Merchant::BankDiscountsController < ApplicationController
  before_action :set_merchant_store
  before_action :set_merchant_bank_discount, only: [:edit, :update]

  # GET /merchant/bank_discounts/new
  def new
    @form = Merchant::BankDiscountForm.new(Pay::BankDiscount.new)
  end

  # GET /merchant/bank_discounts/1/edit
  def edit
    @form = Merchant::BankDiscountForm.new(@bank_discount)
  end

  # POST /merchant/bank_discounts
  def create
    @form = Merchant::BankDiscountForm.new(Pay::BankDiscount.new)
    if @form.validate(merchant_bank_discount_params.merge(merchant_store: @merchant_store))
      if @form.save
        flash[:success] = '创建成功'
        record_activities('创建', '支付计划', "#{@merchant_store.name}")
        redirect_to merchant_merchant_store_payment_plans_path
      else
        flash[:error] = "创建失败: #{@form.model.errors.full_messages}"
        render :new
      end
    else
      flash[:error] = "创建失败: #{@form.errors.full_messages}"
      render :new
    end
  end

  # PATCH/PUT /merchant/bank_discounts/1
  # PATCH/PUT /merchant/bank_discounts/1.json
  def update
    unless @bank_discount.may_edit?
      flash[:error] = '当前支付计划不可修改'
      render :edit and return
    end
    @form = Merchant::BankDiscountForm.new(@bank_discount)
    if @form.validate(merchant_bank_discount_params)
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
  # Use callbacks to share common setup or constraints between actions.
  def set_merchant_bank_discount
    @bank_discount = Pay::BankDiscount.where(merchant_store: @merchant_store, id: params[:id]).first
  end

  def set_merchant_store
    @merchant_store = Merchant::MerchantStore.find(params[:merchant_store_id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def merchant_bank_discount_params
    params[:merchant_bank_discount].except(:status, :plan_type, :id).permit!
  end
end

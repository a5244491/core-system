class Merchant::CreditBacksController < Merchant::MerchantStoreResourcesBasicController
  before_action :set_merchant_credit_back

  # GET /merchant/credit_backs/new
  def new
    @form = Merchant::CreditBackForm.new(Pay::CreditBack.new)
  end

  # GET /merchant/credit_backs/1/edit
  def edit
    @form = Merchant::CreditBackForm.new(@merchant_credit_back)
  end

  # POST /merchant/credit_backs
  # POST /merchant/credit_backs.json
  def create
    @form = Merchant::CreditBackForm.new(Pay::CreditBack.new)
    if @form.validate(merchant_credit_back_params.merge(merchant_store: @merchant_store))
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

  # PATCH/PUT /merchant/credit_backs/1
  # PATCH/PUT /merchant/credit_backs/1.json
  def update
    unless @merchant_credit_back.may_edit?
      flash[:error] = '当前支付计划不可修改'
      render :edit and return
    end
    @form = Merchant::CreditBackForm.new(@merchant_credit_back)
    if @form.validate(merchant_credit_back_params)
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
  def set_merchant_credit_back
    @merchant_credit_back = Pay::CreditBack.where(merchant_store: @merchant_store, id: params[:id]).first
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def merchant_credit_back_params
    params[:merchant_credit_back].except(:status, :plan_type, :id).permit!
  end
end

class Merchant::TransactionRulesController < Merchant::MerchantStoreResourcesBasicController
  before_action :set_merchant_transaction_rule, only: [:edit, :update]
  before_action :prepare_payment_plans, only: [:new, :edit]
  authorize_resource class: 'Merchant::MarketingRule'

  # GET /merchant/transaction_rules/new
  def new
    @form = Merchant::TransactionRuleForm.new(Merchant::TransactionRule.new)
  end

  # GET /merchant/transaction_rules/1/edit
  def edit
    @form = Merchant::TransactionRuleForm.new(@merchant_transaction_rule)
  end

  # POST /merchant/transaction_rules
  # POST /merchant/transaction_rules.json
  def create
    @form = Merchant::TransactionRuleForm.new(Merchant::TransactionRule.new)
    if @form.validate(merchant_transaction_rule_params.merge(merchant_store: @merchant_store))
      if @form.save
        flash[:success] = '创建成功'
        record_activities('创建', '营销规则', "#{@merchant_store.name}")
        redirect_to merchant_merchant_store_marketing_rules_path(@merchant_store)
      else
        flash[:error] = "创建失败: #{@form.model.errors.full_messages}"
        render :new
      end
    else
      flash[:error] = "创建失败: #{@form.errors.full_messages}"
      render :new
    end
  end

  # PATCH/PUT /merchant/transaction_rules/1
  # PATCH/PUT /merchant/transaction_rules/1.json
  def update
    @form = Merchant::TransactionRuleForm.new(@merchant_transaction_rule)
    if @form.validate(merchant_transaction_rule_params)
      if @form.save
        flash[:success] = '修改成功'
        record_activities('修改', '营销规则', "#{@merchant_store.name}")
        redirect_to merchant_merchant_store_marketing_rules_path(@merchant_store)
      else
        flash[:error] = "修改失败: #{@form.model.errors.full_messages}"
        render :edit
      end
    else
      flash[:error] = "修改失败: #{@form.errors.full_messages}"
      render :edit
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_merchant_transaction_rule
      @merchant_transaction_rule = Merchant::TransactionRule.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def merchant_transaction_rule_params
      params[:merchant_transaction_rule].except(:id, :status).permit!
    end

    def prepare_payment_plans
      @payment_plans = @merchant_store.payment_plans
    end
end

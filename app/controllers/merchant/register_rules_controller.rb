class Merchant::RegisterRulesController < Merchant::MerchantStoreResourcesBasicController
  before_action :set_merchant_register_rule, only: [:show, :edit, :update, :destroy]
  authorize_resource class: 'Merchant::MarketingRule'


  # GET /merchant/register_rules/new
  def new
    @form = Merchant::RegisterRuleForm.new(Merchant::RegisterRule.new)
  end

  # GET /merchant/register_rules/1/edit
  def edit
    @form = Merchant::RegisterRuleForm.new(@merchant_register_rule)
  end

  # POST /merchant/register_rules
  # POST /merchant/register_rules.json
  def create
    @form = Merchant::RegisterRuleForm.new(Merchant::RegisterRule.new)
    if @form.validate(merchant_register_rule_params.merge(merchant_store: @merchant_store))
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

  def update
    @form = Merchant::RegisterRuleForm.new(@merchant_register_rule)
    if @form.validate(merchant_register_rule_params)
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
  def set_merchant_register_rule
    @merchant_register_rule = Merchant::RegisterRule.find(params[:id])
  end

# Never trust parameters from the scary internet, only allow the white list through.
  def merchant_register_rule_params
    params[:merchant_register_rule].except(:merchant_store_id, :id).permit!
  end

end

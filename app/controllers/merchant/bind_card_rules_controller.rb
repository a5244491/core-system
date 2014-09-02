class Merchant::BindCardRulesController < Merchant::MerchantStoreResourcesBasicController
  authorize_resource class: 'Merchant::MarketingRule'
  before_action :set_merchant_bind_card_rule, only: [:edit, :update]

  # GET /merchant/bind_card_rules/new
  def new
    @form = Merchant::BindCardRuleForm.new(Merchant::BindCardRule.new)
  end

  # GET /merchant/bind_card_rules/1/edit
  def edit
    @form = Merchant::BindCardRuleForm.new(@merchant_bind_card_rule)
  end

  # POST /merchant/bind_card_rules
  # POST /merchant/bind_card_rules.json
  def create
    @form = Merchant::BindCardRuleForm.new(Merchant::BindCardRule.new)
    if @form.validate(merchant_bind_card_rule_params.merge(merchant_store: @merchant_store))
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

  # PATCH/PUT /merchant/bind_card_rules/1
  # PATCH/PUT /merchant/bind_card_rules/1.json
  def update
    @form = Merchant::BindCardRuleForm.new(@merchant_bind_card_rule)
    if @form.validate(merchant_bind_card_rule_params)
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
  def set_merchant_bind_card_rule
    @merchant_bind_card_rule = Merchant::BindCardRule.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def merchant_bind_card_rule_params
    params[:merchant_bind_card_rule].except(:merchant_store_id, :id).permit!
  end
end

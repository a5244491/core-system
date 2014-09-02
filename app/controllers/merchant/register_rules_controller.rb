class Merchant::RegisterRulesController < Merchant::MerchantStoreResourcesBasicController
  before_action :set_merchant_register_rule, only: [:show, :edit, :update, :destroy]
  authorize_resource class: 'Merchant::MarketingRule'


  # GET /merchant/register_rules/new
  def new
    @merchant_register_rule = Merchant::RegisterRule.new
  end

  # GET /merchant/register_rules/1/edit
  def edit
  end

  # POST /merchant/register_rules
  # POST /merchant/register_rules.json
  def create
    @merchant_register_rule = Merchant::RegisterRule.new(merchant_register_rule_params.merge(merchant_store: @merchant_store))
    if @merchant_register_rule.save
      flash[:success] = '创建成功'
      record_activities('创建', '营销规则', "#{@merchant_store.name}")
      redirect_to merchant_merchant_store_merchant_marketing_rules_path
    else
      flash[:error] = "创建失败: #{@merchant_register_rule.errors.full_messages}"
      render :new
    end
  end

  def update
    respond_to do |format|
      if @merchant_register_rule.update(merchant_register_rule_params)
        format.html { redirect_to @merchant_register_rule, notice: 'Register rule was successfully updated.' }
        format.json { render :show, status: :ok, location: @merchant_register_rule }
      else
        format.html { render :edit }
        format.json { render json: @merchant_register_rule.errors, status: :unprocessable_entity }
      end
    end
  end

# DELETE /merchant/register_rules/1
# DELETE /merchant/register_rules/1.json
  def destroy
    @merchant_register_rule.destroy
    respond_to do |format|
      format.html { redirect_to merchant_register_rules_url, notice: 'Register rule was successfully destroyed.' }
      format.json { head :no_content }
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

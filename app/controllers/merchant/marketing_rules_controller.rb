class Merchant::MarketingRulesController < Merchant::MerchantStoreResourcesBasicController
  before_action :set_merchant_marketing_rule, only: [:destroy, :enable, :disable]
  authorize_resource class: 'Merchant::MarketingRule'


  # GET /merchant/marketing_rules
  # GET /merchant/marketing_rules.json
  def index
    @register_rules = Merchant::RegisterRule.where(merchant_store: @merchant_store).order(created_at: :desc).includes(:post_actions)
    @bind_card_rules = Merchant::BindCardRule.where(merchant_store: @merchant_store).order(created_at: :desc).includes(:post_actions)
    @transaction_rules = Merchant::TransactionRule.where(merchant_store: @merchant_store).order(created_at: :desc).includes(:post_actions)
    @available_voucher_meta = Member::VoucherMeta.active
  end

  def enable
    if @merchant_marketing_rule.may_enable?
      begin
        @merchant_marketing_rule.enable
        record_activities('生效', '营销规则', "#{@merchant_store.name} - #{@merchant_marketing_rule.id}")
        flash[:success] = '操作成功'
      rescue StandardError => e
        flash[:error] = "操作失败: #{e.message}"
      end
    else
      flash[:error] = '操作失败: 当前规则不可生效'
    end
    redirect_to request.referrer
  end

  def disable
    if @merchant_marketing_rule.may_disable?
      begin
        @merchant_marketing_rule.disable
        record_activities('失效', '营销规则', "#{@merchant_store.name} - ##{@merchant_marketing_rule.id}")
        flash[:success] = '操作成功'
      rescue StandardError => e
        flash[:error] = "操作失败: #{e.message}"
      end
    else
      flash[:error] = '操作失败: 当前规则不可失效'
    end
    redirect_to request.referrer
  end

  def destroy
    unless @merchant_marketing_rule.may_destroy?
      flash[:error] = '当前规则不能被删除'
    else
      if @merchant_marketing_rule.destroy
        record_activities('删除', '营销规则',  "#{@merchant_store.name} - ##{@merchant_marketing_rule.id}")
        flash[:success] = Tips::DELETE_SUCCESS
      else
        flash[:error] = Tips::DELETE_ERROR
      end
    end
    redirect_to request.referrer
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_merchant_marketing_rule
      @merchant_marketing_rule = @merchant_store.marketing_rules.find(params[:id] || params[:marketing_rule_id])
    end
end

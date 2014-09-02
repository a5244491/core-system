class Merchant::PostActionsController <ApplicationController
  before_action :set_merchant_post_action, only: [:destroy]
  authorize_resource class: 'Merchant::MarketingRule'

  def destroy
    @merchant_post_action.destroy
    flash[:success] = '删除成功'
    redirect_to request.referer
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_merchant_post_action
      @merchant_post_action = Merchant::PostAction.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def merchant_post_action_params
      params[:merchant_post_action]
    end
end

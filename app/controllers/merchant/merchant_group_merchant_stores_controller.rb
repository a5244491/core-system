class Merchant::MerchantGroupMerchantStoresController < ApplicationController
  before_action :set_merchant_group

  # GET /merchant/merchant_group_merchant_stores
  # GET /merchant/merchant_group_merchant_stores.json
  def index
    @q = @merchant_merchant_group.merchant_stores.search(params[:q])
    @merchant_stores = @q.result.order(created_at: :desc).paginate(page: @page, per_page: @limit)
  end

  # GET /merchant/merchant_group_merchant_stores/new
  def new
    existed_stores = @merchant_merchant_group.merchant_stores.select(:id).to_a
    @q = Merchant::MerchantStore.where.not(id: existed_stores).search(params[:q])
    @merchant_stores = @q.result.order(created_at: :desc).paginate(page: @page, per_page: @limit)
  end

  # GET /merchant/merchant_group_merchant_stores/1/edit
  def edit
  end

  # POST /merchant/merchant_group_merchant_stores
  # POST /merchant/merchant_group_merchant_stores.json
  def create
    unless params[:selected_stores].blank?
      existed_stores = @merchant_merchant_group.merchant_stores.select(:id).to_a
      created = 0
      params[:selected_stores].each do |store|
         unless existed_stores.include?(store)
           if Merchant::MerchantGroupShip.create(merchant_group_id: @merchant_merchant_group.id, merchant_store_id: store)
             created += 1
           end
         end
      end
      flash[:success] = "成功添加#{created}家商户"
    end
    redirect_to request.referrer
  end

  def batch_destroy
    unless params[:selected_stores].blank?
      deleted = Merchant::MerchantGroupShip.where(merchant_store_id: params[:selected_stores].map { |s| s.to_i }).delete_all
      flash[:success] = "成功移除#{deleted}家商户"
    end
    redirect_to request.referrer
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_merchant_group
    @merchant_merchant_group = Merchant::MerchantGroup.find(params[:merchant_group_id])
  end
end

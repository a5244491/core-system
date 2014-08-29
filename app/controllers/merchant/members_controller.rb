class Merchant::MembersController < Merchant::MerchantStoreResourcesBasicController
  before_action :set_merchant_store

  def index
    @q = @merchant_store.member_accounts.search(params[:q])
    @member_accounts = @q.result.order(created_at: :desc).paginate(page: @page, per_page: @limit)
  end
end

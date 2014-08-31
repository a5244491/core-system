class Member::VouchersController < Member::IndividualCreditAccountResourcesController
  def index
    @q = @member_individual_credit_account.vouchers.search(params[:q])
    @member_vouchers = @q.result.order(created_at: :desc).includes(:voucher_meta).paginate(page: @page, per_page: @limit)
  end
end

class Member::VouchersController < Member::IndividualCreditAccountResourcesController
  authorize_resource class: 'Member::Voucher'

  def index
    @q = @member_individual_credit_account.vouchers.search(params[:q])
    @member_vouchers = @q.result.order(created_at: :desc).includes(:voucher_meta).paginate(page: @page, per_page: @limit)
    @voucher_meta = Member::VoucherMeta.active
  end

  def create
    @voucher_meta = Member::VoucherMeta.active.where(id: params[:voucher_meta_id]).first
    unless @voucher_meta.nil?
      begin
        Merchant::VoucherAction.new(voucher_meta: @voucher_meta, voucher_count: params[:voucher_count]).perform_action(credit_account: @member_individual_credit_account)
        flash[:success] = '赠送成功'
      rescue StandardError => e
        flash[:error] = "赠送失败#{e.message}"
      end
    else
      flash[:error] = '红包不存在'
    end
    redirect_to member_individual_credit_account_vouchers_path
  end
end

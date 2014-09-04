module External::Member
  class VouchersAPI < Grape::API
    params do
      requires :credit_account_external_id, type: String
    end
    namespace :members do
      before do
        @credit_account = Member::IndividualCreditAccount.where(external_id: params[:credit_account_external_id]).first!
      end
      get ':credit_account_external_id/vouchers', jbuilder: '/external/member/vouchers/index' do
        @vouchers = @credit_account.vouchers.search(params[:query]).result.includes(:voucher_meta)
        @total = @vouchers.size
        @vouchers = @vouchers.order(id: :desc).paginate(page: current_page, per_page: records_per_page)
      end
    end
  end
end
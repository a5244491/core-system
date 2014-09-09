module External::Member
  class VouchersAPI < Grape::API
    params do
      requires :credit_account_external_id, type: String
    end
    namespace :members do
      before do
        @credit_account = Member::IndividualCreditAccount.where(external_id: params[:credit_account_external_id]).first!
      end
      get ':credit_account_external_id/vouchers' do
        @vouchers = @credit_account.vouchers.search(params[:query]).result.includes(:voucher_meta)
        @total = @vouchers.size
        @vouchers = @vouchers.order(id: :desc).paginate(page: current_page, per_page: records_per_page)
        present :total, @total
        present :records, @vouchers, with: External::Entities::Voucher
      end
    end
  end
end
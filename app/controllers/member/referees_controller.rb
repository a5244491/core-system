class Member::RefereesController < Member::IndividualCreditAccountResourcesController
  authorize_resource class: 'Member::IndividualCreditAccount'
  def index
    @q = Member::CreditAccount.where(referer_account: @member_individual_credit_account).search(params[:q])
    @member_referees = @q.result.order(created_at: :desc).paginate(page: @page, per_page: @limit)
  end
end

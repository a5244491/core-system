class Member::IndividualCreditAccountsController < ApplicationController
  authorize_resource class: 'Member::IndividualCreditAccount'
  before_action :set_member_individual_credit_account, only: [:show]

  def index
    @q = Member::IndividualCreditAccount.search(params[:q])
    @member_individual_credit_accounts = @q.result.order(created_at: :desc).paginate(page: @page, per_page: @limit)
  end

  def show
  end

  private
  def set_member_individual_credit_account
    @member_individual_credit_account = Member::IndividualCreditAccount.find(params[:id])
  end
end

class Member::IndividualCreditAccountResourcesController < ApplicationController
  authorize_resource class: 'Member::BankCard'
  before_action :set_individual_credt_account

  protected
  def set_individual_credt_account
    @member_individual_credit_account = Member::IndividualCreditAccount.find(params[:individual_credit_account_id])
  end
end
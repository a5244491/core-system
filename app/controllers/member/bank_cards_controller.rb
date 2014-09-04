class Member::BankCardsController < Member::IndividualCreditAccountResourcesController
  authorize_resource class: 'Member::BankCard'
  def index
    @member_bank_cards = @member_individual_credit_account.bank_cards
  end
end

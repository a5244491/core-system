class Pay::BankCardNotMatchError < Pay::PaymentPlanError
  def initialize(msg = BANK_CARD_NOT_MATCH)
    super(msg)
  end
end
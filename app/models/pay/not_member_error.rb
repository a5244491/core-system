class Pay::NotMemberError < Pay::PaymentPlanError
  def initialize(msg = Pay::PaymentPlanError::NOT_MEMBER_CARD)
      super(msg)
  end
end
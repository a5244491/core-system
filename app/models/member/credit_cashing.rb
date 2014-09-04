module Member

  class CreditCashingError< StandardError
  end

  class CashingAmountError < CreditCashingError
    def initialize(msg = 'CASHING_AMOUNT_ERROR')
      super(msg)
    end
  end

  class CreditAccountNotFound< CreditCashingError
    def initialize(msg = 'CREDIT_ACCOUNT_NOT_FOUND')
      super(msg)
    end
  end

  class NotNameIsSet< CreditCashingError
    def initialize(msg = 'NOT_NAME_IS_SET')
      super(msg)
    end
  end

  class NotEnoughCredit< CreditCashingError
    def initialize(msg = 'NOT_ENOUGH_CREDIT')
      super(msg)
    end
  end

  class NotCashingCardSpecified< CreditCashingError
    def initialize(msg = 'NOT_CASHING_CARD_SPECIFIED')
      super(msg)
    end
  end
end
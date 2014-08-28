module Pay
  module BankDiscountFormModule
    extend ActiveSupport::Concern

    def discount_amount_in_yuan
      self.discount_amount/100.0
    end

    def discount_amount_in_yuan=(amount)
      self.discount_amount = (amount.to_f * 100).to_i
    end

    def minimal_money_amount_in_yuan
      self.minimal_money_amount/100.0
    end

    def minimal_money_amount_in_yuan=(amount)
      self.minimal_money_amount = (amount.to_f * 100).to_i
    end

    def merchant_rate_in_decimal
      self.merchant_rate * 100 unless self.merchant_rate.blank?
    end

    def merchant_rate_in_decimal=(rate)
      self.merchant_rate = rate.to_f/100 unless rate.blank?
    end

    def discount_rate_in_decimal
      self.discount_rate * 100 unless self.discount_rate.blank?
    end

    def discount_rate_in_decimal=(rate)
      self.discount_rate = rate.to_f/100 unless rate.blank?
    end

    def referer_rate_in_decimal
      self.referer_rate * 100 unless self.referer_rate.blank?
    end

    def referer_rate_in_decimal=(rate)
      self.referer_rate = rate.to_f/100 unless rate.blank?
    end

  end
end
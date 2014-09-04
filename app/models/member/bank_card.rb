module Member
  class BankCard < PaymentMedia
    CARD_TYPE = [DEBIT_CARD = 'debit', CREDIT_CARD = 'credit']
    CARD_LENGTH = [CARD_MIN_LEN = 10, CARD_MAX_LEN = 30]
    validates_inclusion_of :card_type, in: CARD_TYPE
    validates_length_of :media_num, :minimum => CARD_MIN_LEN, :maximum => CARD_MAX_LEN, :allow_blank => false
    alias_attribute :card_num, :media_num
    class << self
      def sti_name
        PaymentMedia::BANK_CARD
      end

      def cashing_card
        where(cashing_card: true)
      end
    end

    def set_cashing_card(cashing)
      if cashing
        Member::BankCard.transaction do
          old_cashing_card = self.credit_account.bank_cards.where(cashing_card: true).first
          old_cashing_card.update_attribute :cashing_card, false unless old_cashing_card.nil?
          self.update(cashing_card: true)
        end
      else
        self.update(cashing_card: false)
      end
    end
  end
end
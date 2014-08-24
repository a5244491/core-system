require 'ostruct'
module Bank
  class CardBin< ActiveRecord::Base


    class << self
      def card_bin_match(bank_card_num)
        self.find_by_sql("SELECT * FROM card_bins WHERE '#{bank_card_num}' like concat(bank_bin,'%') ORDER BY length(bank_bin) DESC LIMIT 1")[0]
      end
    end


    def debit_card?
      self.card_type == 1
    end

    def credit_card?
      self.card_type == 2
    end
  end
end
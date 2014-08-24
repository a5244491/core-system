module Trade
  class RollBackTransaction < Transaction
    class << self
      def sti_name
        Transaction::ROLL_BACK
      end
    end
  end
end
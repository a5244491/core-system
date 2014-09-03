module Member
  class MerchantCreditAccount < CreditAccount
    has_one :merchant_store, foreign_key: 'credit_account_id', class_name: 'Merchant::MerchantStore'

    class << self
      def sti_name
        Member::CreditAccount::MERCHANT
      end
    end

    def submit_credit_cashing_application!(amount)
      store = Merchant::MerchantStore.where(credit_account_id: self.id).first
      raise ArgumentError, 'not store is found' if store.nil?
      raise CreditCashingApplication::NoCashingAccountError if store.clearance_account_num.nil? || store.clearance_account_bank.nil?
      submit_application(store.clearance_account_num, store.clearance_account_bank, amount, store.clearance_account_name)
    end
  end
end
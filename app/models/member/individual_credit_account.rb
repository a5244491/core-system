module Member
  class IndividualCreditAccount < CreditAccount
    validates :mobile, uniqueness: true, presence: true
    has_many :payment_media, foreign_key: 'credit_account_id', class_name: 'Member::PaymentMedia'
    has_many :bank_cards, foreign_key: 'credit_account_id'

    MAX_BIND_CARD_NUM = 5

    class << self
      def sti_name
        CreditAccount::INDIVIDUAL
      end
    end

    def issue_voucher(voucher_meta, issue_event: Trade::VoucherTransactionLog::SYSTEM, merchant_store: nil, master_log: nil)
      voucher_meta = VoucherMeta.where(code: voucher_meta).first if voucher_meta.is_a?(String)
      raise VoucherMeta::VoucherNotAvailable if voucher_meta.nil? || !voucher_meta.active?
      issued_voucher = voucher_meta.with_lock do
        if voucher_meta.limit_per_account >= 0 && self.vouchers.where(voucher_meta_id: voucher_meta.id).count >= voucher_meta.limit_per_account
          raise VoucherMeta::VoucherLimitPerAccountExceeded
        end
        voucher = voucher_meta.issue_voucher
        self.vouchers << voucher
        self.save!
        voucher
      end
      transaction_options = {}
      unless merchant_store.nil?
        transaction_options.store(:merchant_name, merchant_store.name)
        transaction_options.store(:merchant_store_id, merchant_store.id)
        transaction_options.store(:merchant_num, merchant_store.merchant_number)
      end
      unless master_log.nil?
        transaction_options.store(:primary_transaction_ref_id, master_log.ref_id)
        transaction_options.store(:transaction_datetime, master_log.transaction_datetime)
      end
      transaction_log = issued_voucher.prepare_voucher_log(transaction_options.merge!(issue_event: issue_event, mobile: self.mobile, transaction_type: Trade::VoucherTransactionLog::ISSUE))
      transaction_log.transaction_datetime ||= Time.now
      transaction_log.save!
      issued_voucher
    end

    def add_bank_card(card_num, card_type, bank_name = nil)
      raise ExceedsBankCardLimitsError if self.bank_cards.count >= MAX_BIND_CARD_NUM
      begin
        bank_cards.create!(card_num: card_num, card_type: card_type, bank_name: bank_name)
      rescue ActiveRecord::RecordInvalid => e
        if e.message.include?('Media num has already been taken')
          raise BankCardTakenError
        end
        raise e
      end
    end

    def bind_bank_card(bank_card, default_bank_name = nil, default_card_type = nil)
      bank_name = default_bank_name
      matched_card_bin = Bank::CardBin.card_bin_match(bank_card)
      bank_name = matched_card_bin.bank_name unless matched_card_bin.nil?
      card_type = default_card_type.blank? ? BankCard::DEBIT_CARD : default_card_type
      card_type = matched_card_bin.credit_card? ? BankCard::CREDIT_CARD : BankCard::DEBIT_CARD unless matched_card_bin.nil?
      add_bank_card(bank_card, card_type, bank_name)
    end

    def submit_credit_cashing_application!(amount)
      cashing_card = bank_cards.cashing_card.first
      raise CreditCashingApplication::NoCashingAccountError if cashing_card.nil?
      raise CreditCashingApplication::NameNotSetError if self.name.blank?
      raise CreditCashingApplication::NotEnoughCreditError if self.usable_credit < amount
      submit_application(cashing_card.card_num, cashing_card.bank_name, amount, self.name)
    end

    def becomes_member_of(merchant)
      if merchant.kind_of?(Merchant::MerchantStore)
        merchant_stores << merchant unless merchant_stores.exists?(merchant)
      elsif merchant.kind_of?(Merchant::MerchantGroup)
        merchant_groups << merchant unless merchant_groups.exists?(merchant)
      end
      save!
    end

    def referee_of?(referer)
      referer = referer.credit_account if referer.kind_of?(Merchant::MerchantStore)
      self.referer_account == referer
    end
  end
end
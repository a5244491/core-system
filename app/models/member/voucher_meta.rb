require 'securerandom'
require 'digest'
module Member
  class VoucherMeta < ActiveRecord::Base
    include Rule
    DEFAULT_INITIAL_AMOUNT = -1
    DEFAULT_LIMIT_PER_ACCOUNT = -1
    DEFAULT_GLOBAL = true

    class VoucherException < StandardError;
    end
    class VoucherAmountExceeded < VoucherException;
    end
    class VoucherNotAvailable < VoucherException;
    end
    class VoucherLimitPerAccountExceeded < VoucherException;
    end

    ISSUER_TYPE = [SELF = 0, MERCHANT = 1, BANK = 2, PARTNER = 3]
    SETTLER_TYPE = ISSUER_TYPE
    APPLICABLE_TYPES = [ALL_STORE = 0, SINGLE_STORE = 1, STORE_GROUP = 2]

    validates_inclusion_of :issuer_type, in: ISSUER_TYPE
    validates_inclusion_of :settler_type, in: SETTLER_TYPE
    validates_inclusion_of :applicable_type, in: APPLICABLE_TYPES
    belongs_to :merchant_group, class_name: Merchant::MerchantGroup
    belongs_to :merchant_store, class_name: 'Merchant::MerchantStore'
    belongs_to :sequence

    delegate :name, :display_name, to: :merchant_group, prefix: true, allow_nil: true
    delegate :name, to: :merchant_store, prefix: true, allow_nil: true

    before_save do
      if self.initial_amount_changed?
        self.amount_left += self.initial_amount - self.initial_amount_was
      end
      self.initial_amount ||= DEFAULT_INITIAL_AMOUNT
      self.limit_per_account ||= DEFAULT_LIMIT_PER_ACCOUNT
    end

    before_validation do
      self.aliases ||= Time.now.strftime('%Y%m%d%H%M%S%L')
      self.code ||= Digest::MD5.hexdigest("#{Time.now.to_s}:#{SecureRandom.uuid}")
      self.issuer_type ||= SELF
      self.settler_type ||= SELF
      self.applicable_type ||= ALL_STORE
    end

    def global?
      self.applicable_type == ALL_STORE
    end

    def issue_voucher
      unless self.initial_amount < 0
        raise Member::VoucherMeta::VoucherAmountExceeded if self.amount_left <= 0
        self.amount_left -= 1
      end
      self.issued_count += 1
      self.save!
      Member::Voucher.create!(voucher_meta: self)
    end

    def applicable_store_name
      case self.applicable_type
        when ALL_STORE
          '联盟商户'
        when SINGLE_STORE
          self.merchant_store_name
        when STORE_GROUP
          self.merchant_group_display_name
      end
    end
  end
end

require 'securerandom'
require 'digest'
module Member
  class CreditAccount < ActiveRecord::Base
    include Member::CreditAccountEngineConcern
    ACCOUNT_TYPES = [INDIVIDUAL = 'individual', MERCHANT = 'merchant']
    ACCOUNT_STATUS = [ACTIVATED = 1, INACTIVATED = 0]
    TYPE_MAP = {
        INDIVIDUAL => 'Member::IndividualCreditAccount',
        MERCHANT => 'Member::MerchantCreditAccount'
    }

    has_many :credit_cashing_applications
    has_many :vouchers, ->{includes(:voucher_meta)}

    class << self
      def find_sti_class(type_name)
        super(TYPE_MAP[type_name.to_s])
      end
    end
    self.inheritance_column = 'account_type'

    before_create :generate_external_id
    belongs_to :referer_account, class_name: 'Member::CreditAccount', foreign_key: :referer_account_id
    has_many :member_ships
    has_many :merchant_stores, through: :member_ships, source: :member_group, source_type: 'Merchant::MerchantStore'
    has_many :merchant_groups, through: :member_ships, source: :member_group, source_type: 'Merchant::MerchantGroup'



    def apply_credit_cashing!(amount)
      self.usable_credit = self.usable_credit - amount
      self.locked_credit = self.locked_credit + amount
      self.save!
    end

    def reject_credit_cashing!(amount)
      self.usable_credit = self.usable_credit + amount
      self.locked_credit = self.locked_credit - amount
      self.save!
    end

    def approve_credit_cashing!(amount)
      self.locked_credit = self.locked_credit - amount
      self.cashed_credit = self.cashed_credit + amount
      self.save!
    end

    def diff_mobile
      "#{self.mobile[0...3]}****#{self.mobile[-4..-1]}"
    end

    protected
    def submit_application(bank_card, bank_name, amount, real_name)
      self.class.transaction do
        Member::CreditCashingApplication.validation_cashing_amount(amount)
        credit_cashing_application = Member::CreditCashingApplication.new
        credit_cashing_application.bank_card = bank_card
        credit_cashing_application.bank_name = bank_name
        credit_cashing_application.real_name = real_name
        credit_cashing_application.amount = amount
        credit_cashing_application.status = Member::CreditCashingApplication::PROCESSING
        credit_cashing_application.credit_account = self
        credit_cashing_application.save!
        apply_credit_cashing!(amount)
        credit_cashing_application
      end
    end

    private
    def generate_external_id
      self.external_id = Digest::MD5.hexdigest("#{Time.now.to_s}:#{SecureRandom.uuid}")
    end
  end
end
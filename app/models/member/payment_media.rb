module Member
  class PaymentMedia < ActiveRecord::Base
    MEDIA_TYPES = [BANK_CARD = 'bank_card']
    TYPE_MAP = { BANK_CARD => 'Member::BankCard' }
    belongs_to :credit_account
    self.inheritance_column = 'media_type'
    validates_inclusion_of :media_type, in: MEDIA_TYPES
    validates :media_num, uniqueness: {scope: :media_type}

    class << self
      def find_sti_class(type_name)
        super(TYPE_MAP[type_name.to_s])
      end
    end
  end
end
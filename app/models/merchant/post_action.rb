module Merchant
  class PostAction < ActiveRecord::Base
    self.inheritance_column = 'action_type'
    ACTION_TYPES = [ISSUE_VOUCHER = 'issue_voucher']
    TYPE_MAP = {
        ISSUE_VOUCHER => 'Merchant::VoucherAction'
    }
    belongs_to :marketing_rule
    belongs_to :voucher_meta, class_name: Member::VoucherMeta
    class << self
      def find_sti_class(type_name)
        super(TYPE_MAP[type_name.to_s])
      end
    end

    def perform_action(params = {})
    end
  end
end
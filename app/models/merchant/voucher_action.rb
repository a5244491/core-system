module Merchant
  class VoucherAction < PostAction
    validates_presence_of :voucher_meta
    class << self
      def sti_name
        PostAction::ISSUE_VOUCHER
      end
    end
  end
end
require 'digest'
require 'composite_primary_keys'
require 'securerandom'
module Trade
  class VoucherTransactionLog < ActiveRecord::Base
    include Checkable
    self.primary_keys = :id, :transaction_datetime
    TRANSACTION_TYPE = [
        ISSUE = 'issue',
        USE = 'use'
    ]
    ISSUE_EVENT = [SYSTEM = 'system', CONSUMPTION = 'consumption']
    validates_inclusion_of :transaction_type, in: TRANSACTION_TYPE
    validates_inclusion_of :issue_event, in: ISSUE_EVENT, if: :issue?
    before_validation do
      now = Time.now
      self.ref_id = Digest::MD5.hexdigest("#{now.to_i}:#{now.nsec}:#{SecureRandom.uuid}")
      self.issue_event ||= SYSTEM if issue?
    end
    scope :recent, ->{where(transaction_datetime: 1.week.ago..1.week.from_now)}

    def issue?
      transaction_type == ISSUE
    end
  end
end
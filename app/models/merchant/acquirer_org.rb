module Merchant
  class AcquirerOrg < ActiveRecord::Base
    validates_presence_of :acquirer_name, :acquirer_code
    validates_uniqueness_of :acquirer_name, :acquirer_code
    self.table_name = 'acquirer_org'
  end
end
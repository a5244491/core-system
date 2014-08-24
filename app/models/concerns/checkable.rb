module Checkable
  extend ActiveSupport::Concern
  CHECKED_STATUS = [NOT_CHECKED = 0, CHECKED = 1]
  included do
    before_validation do
      self.checked ||= NOT_CHECKED
    end
    validates_inclusion_of :checked, in: CHECKED_STATUS
  end
end
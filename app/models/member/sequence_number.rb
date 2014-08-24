module Member
  class SequenceNumber < ActiveRecord::Base
    belongs_to :sequence
    before_validation do
      self.used ||= false
      true
    end
  end
end
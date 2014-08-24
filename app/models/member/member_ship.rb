module Member
  class MemberShip < ActiveRecord::Base
    belongs_to :credit_account
    belongs_to :member_group, polymorphic: true
  end
end
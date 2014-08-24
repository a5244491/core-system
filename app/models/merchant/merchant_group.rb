module Merchant
  class MerchantGroup < ActiveRecord::Base
    validates_presence_of :name
    validates_uniqueness_of :name
    has_many :merchant_group_ships, dependent: :destroy
    has_many :merchant_stores, through: :merchant_group_ships
    has_many :member_ships, as: :member_group, class_name: Member::MemberShip
    has_many :member_accounts, through: :member_ships, source: :credit_account, class_name: Member::CreditAccount
  end
end
module Users
  class SystemUser < ActiveRecord::Base
    ROLE_NAMES = [SALES_ASSIST = 'sales_assist', ADMIN = 'admin',DEPT_MANAGER = 'dept_manager', MERCHANT_SPECIALIST = 'merchant_specialist', NORMAL_USER = 'normal_user']

    has_secure_password
    validates_uniqueness_of :name
    validates_presence_of :role_name
  end
end

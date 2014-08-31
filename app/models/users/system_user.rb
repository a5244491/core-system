module Users
  class SystemUser < ActiveRecord::Base
    ROLE_NAMES = [SALES_ASSIST = 'sales_assist', ADMIN = 'admin', DEPT_MANAGER = 'dept_manager',  NORMAL_USER = 'normal_user']

    has_secure_password
    validates_uniqueness_of :name
    validates_presence_of :role_name

    def has_role?(role)
      role_name == role
    end

    def may_edit?
      role_name != ADMIN
    end

    def may_destroy?
      role_name != ADMIN
    end
  end
end

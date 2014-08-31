module Users::SystemUsersHelper
  def role_name_text(role)
    case role
      when Users::SystemUser::ADMIN
        '管理员'
      when Users::SystemUser::SALES_ASSIST
        '销售助理'
      when Users::SystemUser::DEPT_MANAGER
        '部门经理'
      when Users::SystemUser::NORMAL_USER
        '普通用户'
    end
  end
end

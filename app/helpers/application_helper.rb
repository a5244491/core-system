module ApplicationHelper
  def role_text(role_name)
    case role_name
      when Users::SystemUser::ADMIN
        '系统管理员'
      when Users::SystemUser::SALES_ASSIST
        '销售助理'
      when Users::SystemUser::DEPT_MANAGER
        '部门经理'
      when Users::SystemUser::MERCHANT_SPECIALIST
        '销售专员'
    end
  end

  def datetime_text(datetime)
    datetime.localtime.strftime('%Y年%-m月%-d日%H时%M分%S秒') unless datetime.nil?
  end
end

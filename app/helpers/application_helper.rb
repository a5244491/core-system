module ApplicationHelper
  def role_text(role_name)
    case role_name
      when Users::SystemUser::ADMIN
        '系统管理员'
      when Users::SystemUser::SALES_ASSIST
        '销售助理'
      when Users::SystemUser::DEPT_MANAGER
        '部门经理'
      when Users::SystemUser::NORMAL_USER
        '普通用户'
    end
  end

  def datetime_text(datetime)
    datetime.localtime.strftime(FormFieldsConversion::DATE_TIME_FORMAT) unless datetime.nil?
  end

  def money_in_yuan(money_in_cent)
    money_in_cent.to_i/100.0
  end
end

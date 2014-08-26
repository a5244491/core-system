module LoginHelper
  include SessionManager
  def login(user)
     create_session(user, request.session)
  end

  def create_and_login_user(name, role_name = Users::SystemUser::ADMIN)
    user = create(:system_user, role_name: role_name, name: name, password: 'test', password_confirmation: 'test')
    login(user)
    user
  end

  def current_user
    Users::SystemUser.find(request.session[:login_admin][:id]).first
  end
end
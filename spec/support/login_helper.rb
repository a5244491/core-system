module LoginHelper
  def login(name, password)
    session[:captcha] = 'fake one'
    post :create, username: name, password: password, image_captcha: session[:captcha]
  end

  def create_and_login_user(name, password, role_name = Users::SystemUser::ADMIN)
    user = create(:system_user, role_name: role_name, name: name, password: password, password_confirmation: password)
    login(user.name, user.password)
    user
  end

  def current_user
    Users::SystemUser.find(request.session[:login_admin][:id]).first
  end
end
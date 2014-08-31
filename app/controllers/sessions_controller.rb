class SessionsController < ActionController::Base
  layout :false
  include SessionManager
  include ActivityManager

  def new
    if logged_in?
      redirect_to merchant_merchant_stores_path and return
    end
  end

  def create
    unless valid_captcha? params[:captcha].to_s.upcase
      flash[:error] = '验证码错误'
      redirect_to :root and return
    end
    destroy_session
    system_user = Users::SystemUser.where({:name => params[:username]}).first
    if system_user and system_user.authenticate(params[:password])
      create_session system_user
      record_activities('登录', '登录', "[#{params[:username]}]登录系统")
      redirect_to merchant_merchant_stores_path
    else
      flash[:error] = Tips::LOGIN_ERROR
      render :new
    end
  end

  def destroy
    destroy_session
    redirect_to :root
  end
end

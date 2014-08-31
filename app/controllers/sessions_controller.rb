class SessionsController < ActionController::Base
  layout :false
  layout 'application', only: [:edit_password, :update_password]
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

  def edit_password

  end

  def update_password
    system_user = current_user
    if not system_user.authenticate(params[:old_password])
      flash[:error] = Tips::PASSWORD_ERROR
      render :edit_password
    else
      system_user.password = params[:password]
      system_user.password_confirmation = params[:confirm_password]
      if system_user.save
        flash[:success] = '更新密码成功，请重新登录'
        destroy_session
        redirect_to :root
      else
        flash[:error] = "更新密码失败: #{system_user.errors.full_message}"
        render :edit_password
      end
    end
  end
end

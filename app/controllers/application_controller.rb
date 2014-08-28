class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :reset_last_captcha_code!
  before_action :check_login, :set_paging
  include SessionManager
  include ActivityManager
  rescue_from CanCan::AccessDenied do |exception|
    flash[:error] = '你无权执行该操作'
    redirect_to :root
  end

  def check_login
    unless logged_in?
      flash[:error] = 'Please login in first'
      redirect_to :root
    end
  end

  private
  def current_ability
    @current_ability ||= Ability.new(current_user, params)
  end

  def set_paging
    @page = params[:page] || 1
    @limit = params[:limit] || 20
  end
end

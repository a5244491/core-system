class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  after_filter :reset_last_captcha_code!
  before_filter :check_login
  include SessionManager
  include ActivityManager
  rescue_from CanCan::AccessDenied do |exception|
    flash[:error] = '你无权执行该操作'
    redirect_to :root
  end

  def get_paging_order_info
    {
        :page => params[:page],
        :limit => params[:limit].nil? ? 20 : params[:limit]
    }
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
end

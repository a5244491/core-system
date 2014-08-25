class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  after_filter :reset_last_captcha_code!
  before_filter :check_login
  rescue_from CanCan::AccessDenied do |exception|
    flash[:error] = ''
    redirect_to :root
  end

  def get_paging_order_info
    {
        :page => params[:page],
        :limit => params[:limit].nil? ? 20 : params[:limit]
    }
  end

  def record_activities(action, object, note = nil)
    begin
      System::ActivityLog.create!(user_name: session[:login_admin][:real_name], note: note, action: action, object: object, ip_address: request.remote_ip)
    rescue StandardError => e
      logger.error "failed to log activity log, exception: #{e}"
    end
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

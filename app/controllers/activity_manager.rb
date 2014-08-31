module ActivityManager
  def record_activities(action, object, note = nil)
    begin
      System::ActivityLog.create!(user_name: @current_user.real_name, note: note, action: action, object: object, ip_address: request.remote_ip)
    rescue StandardError => e
      logger.error "failed to log activity log, exception: #{e}"
    end
  end
end
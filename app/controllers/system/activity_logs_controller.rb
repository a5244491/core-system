class System::ActivityLogsController < ApplicationController
  def index
    @q = System::ActivityLog.search(params[:q])
    @system_activity_logs = @q.result.order(id: :desc).paginate(page: @page, per_page: @limit)
  end
end

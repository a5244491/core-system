class System::ConfigurationsController < ApplicationController
  authorize_resource class: 'System::Configuration'
  before_action :set_system_configuration, only: [:edit, :update]

  # GET /system/configurations
  # GET /system/configurations.json
  def index
    @system_configurations = System::Configuration.all
  end

  # GET /system/configurations/1/edit
  def edit
  end


  # PATCH/PUT /system/configurations/1
  # PATCH/PUT /system/configurations/1.json
  def update
    if @system_configuration.update(system_configuration_params)
      record_activities('修改系统配置', @system_configuration.key, params[:value])
      flash[:success] =  '参数修改成功'
      redirect_to system_configurations_path
    else
      flash[:error] = "修改失败: #{@system_configuration.errors.full_message}"
      render :edit
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_system_configuration
    @system_configuration = System::Configuration.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def system_configuration_params
    params[:system_configuration].permit(:value)
  end
end

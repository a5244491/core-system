class System::PlatformAccountsController < ApplicationController
  authorize_resource class: 'System::PlatformAccount'
  before_action :set_system_platform_account, only: [:edit, :update, :destroy]

  # GET /system/platform_accounts
  # GET /system/platform_accounts.json
  def index
    @system_platform_accounts = System::PlatformAccount.all.order(created_at: :desc)
  end

  # GET /system/platform_accounts/new
  def new
    @system_platform_account = System::PlatformAccount.new
  end

  # GET /system/platform_accounts/1/edit
  def edit
  end

  # POST /system/platform_accounts
  # POST /system/platform_accounts.json
  def create
    @system_platform_account = System::PlatformAccount.new(system_platform_account_params)
    if @system_platform_account.save
      record_activities('创建接入账号', @system_platform_account.account_name)
      flash[:success] = '创建接入账号成功'
      redirect_to system_platform_accounts_path
    else
      flash[:error] = "创建失败: #{@system_platform_account.errors.full_message}"
      render :edit
    end
  end

  # PATCH/PUT /system/platform_accounts/1
  # PATCH/PUT /system/platform_accounts/1.json
  def update
    if @system_platform_account.update(system_platform_account_params)
      record_activities('修改接入账号', @system_platform_account.account_name)
      flash[:success] = '修改接入账号成功'
      redirect_to system_platform_accounts_path
    else
      flash[:error] = "修改失败: #{@system_platform_account.errors.full_message}"
      render :edit
    end
  end

  # DELETE /system/platform_accounts/1
  # DELETE /system/platform_accounts/1.json
  def destroy
    if @system_platform_account.destroy
      record_activities('删除接入账号', @system_platform_account.account_name)
      flash[:success] = '删除接入账号成功'
    else
      flash[:error] = "删除失败: #{@system_platform_account.errors.full_message}"
    end
    redirect_to system_platform_accounts_path
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_system_platform_account
    @system_platform_account = System::PlatformAccount.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def system_platform_account_params
    params[:system_platform_account].except(:id).permit!
  end
end

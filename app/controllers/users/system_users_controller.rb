class Users::SystemUsersController < ApplicationController
  authorize_resource class: 'Users::SystemUser'
  before_action :set_system_system_user, only: [:edit, :update, :destroy]

  # GET /system/system_users
  # GET /system/system_users.json
  def index
    @q = Users::SystemUser.search(params[:q])
    @users_system_users = @q.result.order(created_at: :asc).paginate(page: @page, per_page: @limit)
  end

  # GET /system/system_users/new
  def new
    @form = Users::SystemUserForm.new(Users::SystemUser.new(role_name: Users::SystemUser::NORMAL_USER))
  end

  # GET /system/system_users/1/edit
  def edit
    @form = Users::SystemUserForm.new(@users_system_users)
  end

  # POST /system/system_users
  # POST /system/system_users.json
  def create
    @form = Users::SystemUserForm.new(Users::SystemUser.new)
    if @form.validate(system_system_user_params)
      if @form.save
        flash[:success] = '创建成功'
        record_activities('创建', '运维用户', "#{@form.model.name}")
        redirect_to users_system_users_path
      else
        flash[:error] = "创建失败: #{@form.model.errors.full_messages}"
        render :new
      end
    else
      flash[:error] = "创建失败: #{@form.errors.full_messages}"
      render :new
    end
  end

  # PATCH/PUT /system/system_users/1
  # PATCH/PUT /system/system_users/1.json
  def update
    unless @users_system_users.may_edit?
      flash[:error] = '当前用户不可修改'
      render :edit and return
    end
    @form =  Users::SystemUserForm.new(@users_system_users)
    if @form.validate(system_system_user_params)
      if @form.save
        flash[:success] = '修改成功'
        record_activities('修改', '运维用户', "#{@form.model.name}")
        redirect_to request.referrer
      else
        flash[:error] = "修改失败: #{@form.model.errors.full_messages}"
        render :edit
      end
    else
      flash[:error] = "修改失败: #{@form.errors.full_messages}"
      render :edit
    end
  end

  # DELETE /system/system_users/1
  # DELETE /system/system_users/1.json
  def destroy
    unless @users_system_users.may_destroy?
      flash[:error] = '无法删除'
    else
      if @users_system_users.destroy
        record_activities('删除', '运维用户',  "#{@users_system_users.name}")
        flash[:success] = Tips::DELETE_SUCCESS
      else
        flash[:error] = Tips::DELETE_ERROR
      end
    end
    redirect_to request.referrer
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_system_system_user
    @users_system_users = Users::SystemUser.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def system_system_user_params
    params[:users_system_user].except(:id).permit!
  end
end

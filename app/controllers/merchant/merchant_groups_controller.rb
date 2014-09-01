class Merchant::MerchantGroupsController < ApplicationController
  before_action :set_merchant_merchant_group, only: [:show, :edit, :update, :destroy]

  # GET /merchant/merchant_groups
  # GET /merchant/merchant_groups.json
  def index
    @q = Merchant::MerchantGroup.search(params[:q])
    @merchant_merchant_groups = @q.result.order(created_at: :desc).paginate(page: @page, per_page: @limit)
  end


  # GET /merchant/merchant_groups/new
  def new
    @merchant_merchant_group = Merchant::MerchantGroup.new
  end

  # GET /merchant/merchant_groups/1/edit
  def edit
  end

  # POST /merchant/merchant_groups
  # POST /merchant/merchant_groups.json
  def create
    @merchant_merchant_group = Merchant::MerchantGroup.new(merchant_merchant_group_params)
    if @merchant_merchant_group.save
      record_activities('创建', '商户群组', @merchant_merchant_group.name)
      flash[:success] = '创建成功'
      redirect_to merchant_merchant_groups_path
    else
      flash[:error] = "创建失败: #{@merchant_merchant_group.errors.full_message}"
      render :new
    end
  end

  # PATCH/PUT /merchant/merchant_groups/1
  # PATCH/PUT /merchant/merchant_groups/1.json
  def update
    if @merchant_merchant_group.update(merchant_merchant_group_params)
      record_activities('修改', '商户群组', @merchant_merchant_group.name)
      flash[:success] = '修改成功'
      redirect_to merchant_merchant_groups_path
    else
      flash[:error] = "修改失败: #{@merchant_merchant_group.errors.full_message}"
      render :edit
    end
  end

  # DELETE /merchant/merchant_groups/1
  # DELETE /merchant/merchant_groups/1.json
  def destroy
    if @merchant_merchant_group.destroy
      record_activities('删除', '商户群组', @merchant_merchant_group.name)
      flash[:success] = '删除成功'
    else
      flash[:error] = "删除失败: #{@merchant_merchant_group.errors.full_message}"
    end
    redirect_to request.referer
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_merchant_merchant_group
      @merchant_merchant_group = Merchant::MerchantGroup.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def merchant_merchant_group_params
      params[:merchant_merchant_group].except(:id).permit!
    end
end

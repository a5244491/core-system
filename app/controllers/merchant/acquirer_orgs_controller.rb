class Merchant::AcquirerOrgsController < ApplicationController
  authorize_resource class: 'Merchant::AcquirerOrg'

  before_action :set_merchant_acquirer_org, only: [:edit, :update, :destroy]

  # GET /merchant/acquirer_orgs
  # GET /merchant/acquirer_orgs.json
  def index
    @q = Merchant::AcquirerOrg.search(params[:q])
    @merchant_acquirer_orgs = @q.result.order(created_at: :desc).paginate(page: @page, per_page: @limit)
  end


  # GET /merchant/acquirer_orgs/new
  def new
    @merchant_acquirer_org = Merchant::AcquirerOrg.new
  end

  # GET /merchant/acquirer_orgs/1/edit
  def edit
  end

  # POST /merchant/acquirer_orgs
  # POST /merchant/acquirer_orgs.json
  def create
    @merchant_acquirer_org = Merchant::AcquirerOrg.new(merchant_acquirer_org_params)
    if @merchant_acquirer_org.save
      flash[:success] = '收单机构创建成功'
      record_activities('新增', '收单机构', "新增收单机构[#{@merchant_acquirer_org.acquirer_name}]")
      redirect_to merchant_acquirer_orgs_path
    else
      flash[:error] = "收单机构创建失败: #{@merchant_acquirer_org.errors.full_messages}"
      render :new
    end
  end

  def update
    if @merchant_acquirer_org.update(merchant_acquirer_org_params)
      flash[:success] = '收单机构修改成功'
      record_activities('修改', '收单机构', "新增商户[#{@merchant_acquirer_org.acquirer_name}]")
      redirect_to merchant_acquirer_orgs_path
    else
      flash[:error] = "收单机构修改失败: #{@merchant_acquirer_org.errors.full_messages}"
      render :new
    end
  end

  # DELETE /merchant/acquirer_orgs/1
  # DELETE /merchant/acquirer_orgs/1.json
  def destroy
    if @merchant_acquirer_org.destroy
      record_activities('删除', '收单机构', "删除收单机构[#{@merchant_acquirer_org.acquirer_name}]")
      flash[:success] = Tips::DELETE_SUCCESS
      redirect_to merchant_acquirer_orgs_path
    else
      flash[:error] = Tips::DELETE_ERROR
      redirect_to merchant_acquirer_orgs_path
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_merchant_acquirer_org
      @merchant_acquirer_org = Merchant::AcquirerOrg.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def merchant_acquirer_org_params
      params[:merchant_acquirer_org].require(:acquirer_name)
      params[:merchant_acquirer_org].require(:acquirer_code)
      params[:merchant_acquirer_org].except(:id).permit!
    end
end

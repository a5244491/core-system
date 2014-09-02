class Member::VoucherMetaController < ApplicationController
  before_action :set_member_voucher_meta, only: [:show, :edit, :update, :destroy, :active, :inactive]
  authorize_resource class: 'Member::VoucherMeta'

  # GET /member/voucher_meta
  # GET /member/voucher_meta.json
  def index
    @q = Member::VoucherMeta.search(params[:q])
    @member_voucher_meta = @q.result.order(created_at: :desc).paginate(page: @page, per_page: @limit)
  end

  def active
    @member_voucher_meta.update(status: Member::VoucherMeta::ACTIVE)
    flash[:success] = '生效成功'
    record_activities('生效', '红包', "#{@member_voucher_meta.aliases}")
    redirect_to request.referer
  end

  def inactive
    @member_voucher_meta.update(status: Member::VoucherMeta::INACTIVE)
    flash[:success] = '失效成功'
    record_activities('失效', '红包', "#{@member_voucher_meta .aliases}")
    redirect_to request.referer
  end
  # GET /member/voucher_meta/new
  def new
    @form = Member::VoucherMetaForm.new(Member::VoucherMeta.new)
  end

  # GET /member/voucher_meta/1/edit
  def edit
    @form = Member::VoucherMetaForm.new(@member_voucher_meta)
  end

  # POST /member/voucher_meta
  # POST /member/voucher_meta.json
  def create
    @form = Member::VoucherMetaForm.new(Member::VoucherMeta.new)
    if @form.validate(member_voucher_meta_params)
      if @form.save
        flash[:success] = '创建成功'
        record_activities('创建', '红包', "#{@form.aliases}")
        redirect_to member_voucher_meta_index_path
      else
        flash[:error] = "创建失败: #{@form.model.errors.full_messages}"
        render :new
      end
    else
      flash[:error] = "创建失败: #{@form.errors.full_messages}"
      render :new
    end
  end

  # PATCH/PUT /member/voucher_meta/1
  # PATCH/PUT /member/voucher_meta/1.json
  def update
    unless @member_voucher_meta.may_edit?
      flash[:error] = '当前红包不可修改'
      render :edit and return
    end
    @form = Member::VoucherMetaForm.new(@member_voucher_meta)
    if @form.validate(member_voucher_meta_params)
      if @form.save
        flash[:success] = '修改成功'
        record_activities('修改', '红包', "#{@form.aliases}")
        redirect_to member_voucher_meta_index_path
      else
        flash[:error] = "修改失败: #{@form.model.errors.full_messages}"
        render :edit
      end
    else
      flash[:error] = "修改失败: #{@form.errors.full_messages}"
      render :edit
    end
  end

  # DELETE /member/voucher_meta/1
  # DELETE /member/voucher_meta/1.json
  def destroy
    unless @member_voucher_meta.may_destroy?
      flash[:error] = '无法删除'
    else
      if @member_voucher_meta.destroy
        record_activities('删除', '红包', "#{@member_voucher_metum.aliases}")
        flash[:success] = Tips::DELETE_SUCCESS
      else
        flash[:error] = Tips::DELETE_ERROR
      end
    end
    redirect_to request.referrer
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_member_voucher_meta
      @member_voucher_meta = Member::VoucherMeta.find(params[:id] || params[:voucher_meta_id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def member_voucher_meta_params
      params[:member_voucher_meta].except(:id, :status).permit!
    end
end

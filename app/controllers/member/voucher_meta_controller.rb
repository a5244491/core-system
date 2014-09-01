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
    @member_voucher_metum.update(status: Member::VoucherMeta::ACTIVE)
    flash[:success] = '生效成功'
    record_activities('生效', '红包', "#{@member_voucher_metum.aliases}")
    redirect_to request.referer
  end

  def inactive
    @member_voucher_metum.update(status: Member::VoucherMeta::INACTIVE)
    flash[:success] = '失效成功'
    record_activities('失效', '红包', "#{@member_voucher_metum.aliases}")
    redirect_to request.referer
  end
  # GET /member/voucher_meta/new
  def new
    @member_voucher_metum = Member::VoucherMetum.new
  end

  # GET /member/voucher_meta/1/edit
  def edit
  end

  # POST /member/voucher_meta
  # POST /member/voucher_meta.json
  def create
    @member_voucher_metum = Member::VoucherMetum.new(member_voucher_metum_params)

    respond_to do |format|
      if @member_voucher_metum.save
        format.html { redirect_to @member_voucher_metum, notice: 'Voucher metum was successfully created.' }
        format.json { render :show, status: :created, location: @member_voucher_metum }
      else
        format.html { render :new }
        format.json { render json: @member_voucher_metum.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /member/voucher_meta/1
  # PATCH/PUT /member/voucher_meta/1.json
  def update
    respond_to do |format|
      if @member_voucher_metum.update(member_voucher_metum_params)
        format.html { redirect_to @member_voucher_metum, notice: 'Voucher metum was successfully updated.' }
        format.json { render :show, status: :ok, location: @member_voucher_metum }
      else
        format.html { render :edit }
        format.json { render json: @member_voucher_metum.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /member/voucher_meta/1
  # DELETE /member/voucher_meta/1.json
  def destroy
    unless @member_voucher_metum.may_destroy?
      flash[:error] = '无法删除'
    else
      if @member_voucher_metum.destroy
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
      @member_voucher_metum = Member::VoucherMeta.find(params[:id] || params[:voucher_metum_id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def member_voucher_metum_params
      params[:member_voucher_metum]
    end
end

module Merchant
  class MerchantStoresController < ApplicationController
    before_action :set_merchant_merchant_store, except: [:new, :create, :index]
    authorize_resource class: 'Merchant::MerchantStore'

    def index
      @q = Merchant::MerchantStore.search(params[:q])
      @merchant_stores = @q.result.order(created_at: :desc).paginate(page: @page, per_page: @limit)
    end

    def show
    end

    def new
      @merchant_store = Merchant::MerchantStore.new
    end

    def edit
    end

    def create
      @merchant_store = Merchant::MerchantStore.new(merchant_merchant_store_params)
      if @merchant_store.save
        flash[:success] = '商户创建成功'
        record_activities('新增', '商户管理', "新增商户[#{@merchant_store.name}]")
        redirect_to @merchant_store
      else
        flash[:error] = "商户创建失败: #{@merchant_store.errors.full_messages}"
        render :new
      end
    end

    def update
      if @merchant_store.may_edit?
        if @merchant_store.update(merchant_merchant_store_params)
          record_activities('修改', '商户管理', "修改商户[#{merchant_merchant_store_params[:name]}]")
          flash[:success] = '修改商户资料成功'
          redirect_to @merchant_store
        else
          flash[:error] = "修改商户资料失败: #{@merchant_store.errors.full_messages}"
          render :edit
        end
      else
        flash[:error] = '只有录入中的商户才能编辑'
        render 'merchant/merchant_stores/edit'
      end
    end

    def destroy
      unless @merchant_store.may_destroy?
        flash[:error] = Tips::MERCHANT_CAN_NOT_DELETE
        redirect_to request.referrer and return
      end

      if @merchant_store.destroy
        record_activities('删除', '商户管理', "删除商户[#{@merchant_store.name}]")
        flash[:success] = Tips::DELETE_SUCCESS
        redirect_to merchant_merchant_stores_path
      else
        flash[:error] = Tips::DELETE_ERROR
        redirect_to request.referrer and return
      end
    end

    def submit_audit
      store_status_operation(:submit_audit)
    end

    def reject_audit
      store_status_operation(:reject_audit)
    end

    def approve_audit
      store_status_operation(:approve_audit)
    end

    def enable
      store_status_operation(:enable)
    end

    def disable
      store_status_operation(:disable)
    end

    private
    def store_status_operation(status)
      begin
        case status
          when :submit_audit
            @merchant_store.submit_audit!
            record_activities('审核', '商户管理', "提交商户[#{@merchant_store.name}]")
          when :reject_audit
            @merchant_store.reject_audit!
            record_activities('审核', '商户管理', "审核被拒商户[#{@merchant_store.name}]")
          when :approve_audit
            @merchant_store.approve_audit!
            record_activities('审核', '商户管理', "审核通过商户[#{@merchant_store.name}]")
          when :enable
            @merchant_store.enable!
            record_activities('上线', '商户管理', "上线商户[#{@merchant_store.name}]")
          when :disable
            @merchant_store.disable!
            record_activities('下线', '商户管理', "下线商户[#{@merchant_store.name}]")
          else
            raise IllegalOperationException, '错误的操作'
        end
        flash[:success] = '审核成功'
      rescue StandardError => e
        flash[:error] = "审核失败, #{e.message}"
      end
      redirect_to request.referrer
    end

    private
    def set_merchant_merchant_store
      @merchant_store = Merchant::MerchantStore.find(params[:id] || params[:merchant_store_id])
    end

    def merchant_merchant_store_params
      params[:merchant_merchant_store].require(:name)
      params[:merchant_merchant_store].require(:standard_rate)
      params[:merchant_merchant_store].require(:merchant_number)
      params[:merchant_merchant_store].except(:id, :status).permit!
    end
  end
end
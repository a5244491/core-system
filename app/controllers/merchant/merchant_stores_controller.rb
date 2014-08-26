module Merchant
  class MerchantStoresController < ApplicationController
    before_action :set_merchant_merchant_store, only: [:show, :edit, :update, :destroy]
    authorize_resource class: 'Merchant::MerchantStore'
    # GET /merchant/merchant_stores
    # GET /merchant/merchant_stores.json
    def index
      @merchant_stores = Merchant::MerchantStore.order(created_at: :desc).paginate(page: @page, per_page: @limit)
    end

    # GET /merchant/merchant_stores/1
    # GET /merchant/merchant_stores/1.json
    def show
    end

    # GET /merchant/merchant_stores/new
    def new
      @merchant_store = Merchant::MerchantStore.new
    end

    # GET /merchant/merchant_stores/1/edit
    def edit
    end

    # POST /merchant/merchant_stores
    # POST /merchant/merchant_stores.json
    def create
      @merchant_merchant_store = Merchant::MerchantStore.new(merchant_merchant_store_params)

      respond_to do |format|
        if @merchant_merchant_store.save
          format.html { redirect_to @merchant_merchant_store, notice: 'Merchant store was successfully created.' }
          format.json { render :show, status: :created, location: @merchant_merchant_store }
        else
          format.html { render :new }
          format.json { render json: @merchant_merchant_store.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /merchant/merchant_stores/1
    # PATCH/PUT /merchant/merchant_stores/1.json
    def update
      respond_to do |format|
        if @merchant_merchant_store.update(merchant_merchant_store_params)
          format.html { redirect_to @merchant_merchant_store, notice: 'Merchant store was successfully updated.' }
          format.json { render :show, status: :ok, location: @merchant_merchant_store }
        else
          format.html { render :edit }
          format.json { render json: @merchant_merchant_store.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /merchant/merchant_stores/1
    # DELETE /merchant/merchant_stores/1.json
    def destroy
      @merchant_merchant_store.destroy
      respond_to do |format|
        format.html { redirect_to merchant_merchant_stores_url, notice: 'Merchant store was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    private
    # Use callbacks to share common setup or constraints between actions.
    def set_merchant_merchant_store
      @merchant_merchant_store = Merchant::MerchantStore.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def merchant_merchant_store_params
      params[:merchant_merchant_store]
    end
  end
end

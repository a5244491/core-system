module External::Merchant
  class MerchantStoresAPI < Grape::API
    namespace :merchant_stores do
      get '/', jbuilder: 'external/merchant/merchant_stores/index' do
        @merchant_stores = ::Merchant::MerchantStore.search(params[:query]).result
        @total = @merchant_stores.size
        @merchant_stores = @merchant_stores.paginate(page: current_page, per_page: records_per_page)
      end

      params do
        requires :merchant_store_id, type: Integer
        requires :id, type: Integer
      end
      namespace ':merchant_store_id/transaction_logs/:id' do
        params do
          requires :data, type: Hash do
            requires :checked, type: Integer
          end
        end
        before do
          @log = Trade::TransactionLog.where(id: params[:id], merchant_store_id: params[:merchant_store_id]).first!
        end
        put '/' do
          @log.checked = params[:data][:checked]
          @log.save!
          render_success
        end
      end
    end
  end
end

#encoding:utf-8
class External::VouchersAPI < Grape::API
  params do
    requires :credit_account_external_id, type: String
  end
  get '/vouchers', rabl: '/vouchers/index' do
    credit_account = CoreLib::CreditAccount.where(:external_id => params[:credit_account_external_id]).first!
    @vouchers = credit_account.vouchers
    @vouchers = @vouchers.not_used if params[:status] == CoreLib::Voucher::NOT_USED
    @vouchers = @vouchers.used if params[:status] == CoreLib::Voucher::USED
    # @vouchers = @vouchers.where('valid_from >= ?', Time.zone.parse(params[:valid_from])) unless params[:valid_from].blank?
    # @vouchers = @vouchers.where('valid_till <= ?', Time.zone.parse(params[:valid_till])) unless  params[:valid_till].blank?
    # @vouchers = @vouchers.where('valid_till <= ?', '2014-8-10')

  end


  params do
    requires :credit_account_external_id, type: String
  end
  get '/voucher_meta', rabl: '/vouchers/meta' do
    credit_account = CoreLib::CreditAccount.where(:external_id => params[:credit_account_external_id]).first!
    merchant_store = CoreLib::MerchantStore.select('id', 'name').where('credit_account_id = ?', credit_account.id).first!
    # CoreLib::VoucherMeta
    conditions = {:merchant_store_name => merchant_store.name}
    sql = 'SELECT sum(m.amount_left) as amount_left,
                  (m.amount_left * m.denomination) as total_left,
                  sum(m.initial_amount) as num_total
            FROM
                voucher_meta m
            where
                m.issuer_identifier = :merchant_store_name'
    @logs = CoreLib::VoucherMeta.find_by_sql([sql, conditions])
  end


  params do
    requires :credit_account_external_id, type: String
  end
  get '/voucher_meta/list', rabl: '/vouchers/meta_list' do
    credit_account = CoreLib::CreditAccount.where(:external_id => params[:credit_account_external_id]).first!
    merchant_store = CoreLib::MerchantStore.select('id', 'name').where('credit_account_id = ?', credit_account.id).first!
    logs = CoreLib::VoucherMeta.where('merchant_store_id = ?', merchant_store.id)
    logs = logs.where('valid_from >= ?', params[:start]) unless params[:start].blank?
    logs = logs.where('valid_till <= ?', params[:end]) unless params[:end].blank?
    logs = logs.where('aliases like ?', "%#{params[:aliases]}%") unless params[:aliases].blank?
    logs = logs.where('denomination = ?', params[:denomination]) unless params[:denomination].blank?
    status = params[:status]
    if(!status.blank?)
      if(status == '*')
        logs = logs.where('status = 1 and sysdate() > valid_till')
      elsif (status == '1')
        logs = logs.where('status = 1 and sysdate() <= valid_till' )
      else
        logs = logs.where('status = 0' )
      end
    end



    @sum = {}
    if params[:sum].kind_of?(Array)
      params[:sum].each do |p|
        @sum.store(p, logs.calculate(:sum, p.to_sym))
      end
    end
    @total = logs.count
    logs = logs.offset(params[:offset].to_i) unless params[:offset].blank?
    logs = logs.limit(params[:limit].to_i) unless params[:limit].blank?
    @logs = logs.order('created_at desc')
  end


end
class MarketingRuleWorker
  include Sidekiq::Worker
  sidekiq_options queue: :post_actions, unqiue: true

  def perform(trigger_event, credit_account_id, merchant_store_id = nil, master_log_ref_id = nil)
    merchant_store = Merchant::MerchantStore.where(id: merchant_store_id).first
    unless merchant_store.nil?
      merchant_store.perform_marketing_rule(trigger_event, credit_account_id, master_log_ref_id)
    end
  end
end
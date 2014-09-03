module Merchant
  module MerchantStoreEngineConcern
    extend ActiveSupport::Concern
    included do
      scope :valid, -> { active }
    end

    def new_transaction(params = {})
      @money_amount = params[:money_amount]
      @media_num = params[:media_num]
      @media_type = params[:media_type]
      raise ArgumentError if @money_amount.nil? or @media_num.nil?

      @payment_media = Member::BankCard.where(media_num: @media_num).first
      @credit_account = @payment_media.nil? ? nil : @payment_media.credit_account

      @payment_plan = find_right_plan(params[:plan_type], @media_num, @credit_account)
      raise Pay::PaymentPlanError, "金额满#{@payment_plan.minimal_money_amount/100.0}元才能享受此优惠" if @money_amount < @payment_plan.minimal_money_amount
      raise Pay::NotMemberError if @credit_account.nil? && @payment_plan.member_only?

      @transaction = @payment_plan.create_transaction(@money_amount, @credit_account)
      raise Pay::PaymentPlanError('支付计划异常') if @transaction.actual_money_amount > @money_amount
      @transaction = save_transaction
    end


    def perform_marketing_rule(trigger_event, credit_account, master_log_ref_id = nil)
      rules = marketing_rules.where(rule_type: trigger_event).active
      unless rules.empty?
        if trigger_event == MarketingRule::TRANSACTION
          master_log = Trade::TransactionLog.transaction do
            Trade::TransactionLog.where(ref_id: master_log_ref_id).primary_log.first
          end
          payment_plan = Pay::PaymentPlan.where(id: master_log.payment_plan_id).first unless master_log.nil?
          rules = payment_plan.nil? ? Pay::PaymentPlan.none : payment_plan.marketing_rules.on_transaction.active
        end
        account = if credit_account.instance_of?(Member::CreditAccount)
                    credit_account
                  else
                    Member::CreditAccount.where(id: credit_account).first
                  end
        rules.each do |rule|
          rule.perform_post_actions(account, master_log)
        end
      end
    end

    private
    def find_right_plan(plan_type, media_num, credit_account)
      candidates = payment_plans.where(plan_type: plan_type).valid.to_a
      raise Pay::NoPlanSelectedError if candidates.size == 0
      candidates = select_plan_by_bank(candidates, media_num)
      candidates.first
    end

    def select_plan_by_bank(candidates, bank_card_number)
      banks = candidates.select { |c| !c.bank_name.blank? }.map { |c| c.bank_name }
      matched_card_bin = nil
      unless banks.empty?
        card_bins = Bank::CardBin.where(bank_name: banks).select('bank_bin, bank_name')
        card_bins.each do |card_bin|
          if bank_card_number.start_with?(card_bin.bank_bin) && (matched_card_bin.nil? || matched_card_bin.bank_bin.length < card_bin.bank_bin.length)
            matched_card_bin = card_bin
          end
        end
      end
      matched_bank = matched_card_bin.bank_name unless matched_card_bin.nil?
      candidates = candidates.select { |c| c.bank_name.to_s == matched_bank.to_s }
      raise Pay::BankCardNotMatchError if candidates.size == 0
      candidates
    end

    def save_transaction
      @transaction.actual_money_amount = 1 if @transaction.actual_money_amount == 0
      @transaction.merchant_rate ||= @payment_plan.merchant_rate
      @transaction.consumer_credit ||= (@transaction.actual_money_amount * @payment_plan.customer_rate.to_f).to_i
      @transaction.referer_credit ||= (@transaction.actual_money_amount * @payment_plan.actual_referer_rate.to_f).to_i
      @transaction.plan_name = @payment_plan.plan_name
      @transaction.merchant_name = self.name
      @transaction.money_amount = @money_amount
      @transaction.payment_plan_id = @payment_plan.id
      @transaction.merchant_store_id = self.id
      @transaction.media_num = @media_num
      @transaction.merchant_num = self.merchant_number
      @transaction.media_type = @media_type
      @transaction.plan_type = @payment_plan.plan_type
      @transaction.acquirer_code = self.acquire_org.acquirer_code unless self.acquire_org.nil?
      @transaction.merchant_tag = self.tag
      unless @credit_account.nil?
        @transaction.mobile = @credit_account.mobile
        @transaction.customer_name = @credit_account.name
        @transaction.credit_account_id = @credit_account.id
        @transaction.user_tag = @credit_account.tag
      end
      @transaction.save!
      @transaction
    end
  end
end
require 'spec_helper'

describe Merchant::MarketingRule do
  describe 'persistence' do
    before :each do
      @store = create(:merchant_store)
      @register = create(:register_rule, merchant_store: @store)
      @bind = create(:bind_card_rule, merchant_store: @store)
      @transaction_rule = create(:transaction_rule, merchant_store: @store)
      @payment_plan = create(:none_payment_plan, merchant_store: @store)
      @payment_plan.marketing_rules << @transaction_rule
      @payment_plan.save!
    end

    it 'should persist' do
      Merchant::MarketingRule.on_transaction.count.should == 1
      Merchant::MarketingRule.on_transaction.first.should be_a(Merchant::TransactionRule)

      Merchant::MarketingRule.on_register.count.should == 1
      Merchant::MarketingRule.on_register.first.should be_a(Merchant::RegisterRule)

      Merchant::MarketingRule.on_bind_card.count.should == 1
      Merchant::MarketingRule.on_bind_card.first.should be_a(Merchant::BindCardRule)

      @store.marketing_rules.size.should == 3
      @payment_plan.marketing_rules.size.should == 1
    end
  end
end

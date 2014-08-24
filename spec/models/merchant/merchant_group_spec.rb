require 'spec_helper'

describe Merchant::MerchantGroup do
  describe 'persistence' do
    before :each do
      @store = create(:merchant_store)
    end

    it 'should create group with one store' do
      group = Merchant::MerchantGroup.create!(name: 'test_group')
      group.merchant_stores << @store
      group.save!
      group.reload.merchant_stores.count.should == 1
      @store.reload.merchant_groups.count.should == 1
      @store.merchant_groups.first.should == group
    end
  end
end

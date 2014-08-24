require 'spec_helper'

describe Member::MemberShip do
  before :each do
    @credit_account = create(:individual_credit_account)
    @store = create(:merchant_store)
    @group = create(:merchant_group)
  end

  it 'should add member to store' do
    @credit_account.merchant_stores << @store
    @credit_account.save!
    @credit_account.merchant_stores.count.should == 1
    @store.member_accounts.size.should == 1
  end

  it 'should add member to merchant group' do
    @credit_account.merchant_groups << @group
    @credit_account.save!
    @credit_account.merchant_groups.count.should == 1
    @group.member_accounts.size.should == 1
  end
end

require 'spec_helper'

describe Trade::CreditBackTransaction do
  it 'should save' do
    Trade::CreditBackTransaction.create!
    Trade::Transaction.count.should == 1
    Trade::Transaction.first.ref_id.should_not be_nil
  end
end

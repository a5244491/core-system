require 'spec_helper'

describe Trade::RollBackTransaction do
  it 'should save' do
    Trade::RollBackTransaction.create!
    Trade::Transaction.count.should == 1
    Trade::Transaction.first.ref_id.should_not be_nil
  end
end

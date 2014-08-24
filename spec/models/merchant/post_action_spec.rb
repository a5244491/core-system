require 'spec_helper'

describe Merchant::PostAction do
  describe 'persistence' do
    before :each do
      @voucher_meta = create(:voucher_meta)
      @marketing_rule = create(:transaction_rule)
    end

    it 'should persist with relations' do
      post_action = Merchant::VoucherAction.create!(voucher_meta: @voucher_meta, marketing_rule: @marketing_rule)
      @marketing_rule.post_actions.count.should == 1
      @marketing_rule.post_actions.first.id.should == post_action.id
      @marketing_rule.post_actions.first.should be_a(Merchant::VoucherAction)
    end

    describe Merchant::VoucherAction do
      it 'should not persist if voucher_meta is not specified' do
        expect {Merchant::VoucherAction.create!(marketing_rule: @marketing_rule)}.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end
end

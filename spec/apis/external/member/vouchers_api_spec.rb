require 'spec_helper'

describe External::Member::VouchersAPI do

  before :each do
    @account = create(:individual_credit_account, mobile: '13982007900')
  end


  describe 'get /vouchers' do
    it 'get vouchers by external_id' do
      get "/external/members/#{@account.external_id}/vouchers"
      response.status.should be == 200
    end
  end
end
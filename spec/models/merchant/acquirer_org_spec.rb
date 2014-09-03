require 'spec_helper'

describe Merchant::AcquirerOrg do
  it 'should save' do
    Merchant::AcquirerOrg.create!(acquirer_name:'cangjingkong', acquirer_code: '1111').should be_true
  end
end

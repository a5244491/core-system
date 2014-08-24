require 'spec_helper'

describe Merchant::AcquirerOrg do
  it 'should save' do
    Merchant::AcquirerOrg.create!(acquirer_name:'cangjingkong').should be_true
  end
end

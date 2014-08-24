require 'spec_helper'

describe System::PlatformAccount do
  before :each do
    @account = System::PlatformAccount.create!(account_name: 'test', access_target: System::PlatformAccount::CORE_ENGINE, status: System::PlatformAccount::ACTIVE)
  end

  it 'should validates account' do
    System::PlatformAccount.validate(@account.account_name, 'wrong', System::PlatformAccount::CORE_ENGINE).should be_nil
    System::PlatformAccount.validate(@account.account_name, @account.access_key, System::PlatformAccount::CORE_INTERFACE).should be_nil
    System::PlatformAccount.validate('wrong', @account.access_key, System::PlatformAccount::CORE_ENGINE).should be_nil
    account = System::PlatformAccount.validate(@account.account_name, @account.access_key, System::PlatformAccount::CORE_ENGINE)
    account.should_not be_nil
    account.account_name.should == @account.account_name
  end

  it 'should fail for validation of inactive account' do
    @account.update_attribute(:status, System::PlatformAccount::INACTIVE)
    System::PlatformAccount.validate(@account.account_name, @account.access_key, System::PlatformAccount::CORE_ENGINE).should be_nil
  end
end

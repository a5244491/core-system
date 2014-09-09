module EngineHelper
  def platform_account_key_secret
    account = System::PlatformAccount.first_or_create!(account_name: 'test', access_target: System::PlatformAccount::CORE_ENGINE, status: System::PlatformAccount::ACTIVE)
    {
        api_key: account.access_key
    }
  end
end
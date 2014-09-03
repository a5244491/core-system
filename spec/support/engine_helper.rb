module EngineHelper
  def platform_account_header
    account = System::PlatformAccount.first_or_create!(account_name: 'test', access_target: System::PlatformAccount::CORE_ENGINE, status: System::PlatformAccount::ACTIVE)
    {
        'HTTP_X_ACCOUNT_NAME' => account.account_name,
        'HTTP_X_ACCESS_KEY' => account.access_key
    }
  end
end
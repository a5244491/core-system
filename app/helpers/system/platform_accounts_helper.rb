module System::PlatformAccountsHelper
  def status_list
    [
        ['生效', System::PlatformAccount::ACTIVE],
        ['失效', System::PlatformAccount::INACTIVE],
    ]
  end

  def status_text(status)
    case status
      when System::PlatformAccount::ACTIVE
        '生效'
      when System::PlatformAccount::INACTIVE
        '失效'
    end
  end

  def target_list
    [
        ['核心平台', System::PlatformAccount::CORE_ENGINE],
        ['核心接口', System::PlatformAccount::CORE_INTERFACE],
    ]
  end

  def target_text(target)
    case target
      when System::PlatformAccount::CORE_ENGINE
        '核心平台'
      when System::PlatformAccount::CORE_INTERFACE
        '核心接口'
    end
  end
end

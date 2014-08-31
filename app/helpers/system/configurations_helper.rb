module System::ConfigurationsHelper
  KEY_TEXT = {
      System::Configuration::REFERER_RATE => '推荐人折扣率(例: 0.001为千分之一)'
  }

  def configuration_description(configuration)
    KEY_TEXT[configuration.key] || configuration.key
  end
end

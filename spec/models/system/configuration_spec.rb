require 'spec_helper'

describe System::Configuration do
  it 'should get and set value' do
    System::Configuration.set(System::Configuration::REFERER_RATE, 0.3)
    System::Configuration.get(System::Configuration::REFERER_RATE).should == '0.3'
  end

  it 'should remove value' do
    System::Configuration.set(System::Configuration::REFERER_RATE, 0.3)
    System::Configuration.remove(System::Configuration::REFERER_RATE)
    System::Configuration.get(System::Configuration::REFERER_RATE).should be_nil
  end
end

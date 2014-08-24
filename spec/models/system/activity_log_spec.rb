require 'spec_helper'

describe System::ActivityLog do
  it 'should save' do
    System::ActivityLog.create!(user_name:'tester').should be_true
  end
end

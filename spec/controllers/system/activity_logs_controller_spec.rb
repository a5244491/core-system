require 'spec_helper'

describe System::ActivityLogsController do
  render_views
  before :each do
    create_and_login_user('test', Users::SystemUser::DEPT_MANAGER)
  end

  describe 'index action' do
    it 'show index show template and response 200' do
      get :index
      response.code.should eq('200')
      response.should render_template('index')
    end
  end
end

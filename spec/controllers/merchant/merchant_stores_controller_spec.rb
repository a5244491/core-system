require 'spec_helper'

describe Merchant::MerchantStoresController do
  render_views
  before(:each) do
    create_and_login_user('test', Users::SystemUser::DEPT_MANAGER)
  end

  it 'render index template and response 200' do
    get :index
    response.code.should eq('200')
    response.should render_template('merchant/merchant_stores/index')
  end
end

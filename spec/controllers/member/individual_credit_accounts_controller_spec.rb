require 'spec_helper'

describe Member::IndividualCreditAccountsController do
  render_views
  before(:each) do
    @individual_account = create(:individual_credit_account, mobile: '15828177722', bank_card: '223123211121212121212121212')
    @bank_card = @individual_account.bank_cards.first
    create_and_login_user('test', Users::SystemUser::DEPT_MANAGER)
  end

  describe 'index action' do
    it 'should render individual template and response 200' do
      get :index
      response.code.should eq('200')
      response.should render_template('index')
    end
  end
end

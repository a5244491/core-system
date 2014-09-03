module Engine::POS
  class PosAPI < Grape::API
    group :pos do
      mount Engine::POS::MembersAPI
      mount Engine::POS::CreditsAPI
      mount Engine::POS::TransactionsAPI
    end
  end
end
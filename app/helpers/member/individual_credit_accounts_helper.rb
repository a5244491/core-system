module Member::IndividualCreditAccountsHelper
  def referer_link(credit_account)
    referer_account = credit_account.referer_account
    unless referer_account.nil?
      if referer_account.instance_of?(Member::MerchantCreditAccount)
        %Q{<a href="#{merchant_merchant_store_path(referer_account.merchant_store)}">#{referer_account.name}</a>}
      else
        %Q{<a href="#{member_individual_credit_account_path(referer_account)}">#{referer_account.mobile}</a>}
      end.html_safe
    end
  end
end

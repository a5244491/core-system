class Ability
  include CanCan::Ability

  def initialize(user, params)
    user ||= Users::SystemUser.new
    alias_action :show, :index, :all_plans, :available, :dialog, to: :read
    alias_action :edit, :update, :create, :new, :read, to: :basic_edit
    alias_action :inactive, :active, to: :change_rule_status
    if user.has_role? Users::SystemUser::ADMIN
      can :manage, :all
    end
    define_merchant_store_abilities(user, params)
    define_payment_plan_abilities(user, params)
    define_marketing_plan_abilities(user, params)
    define_post_action_abilities(user, params)
    define_merchant_group_abilities(user, params)
    define_acquirer_abilities(user, params)
    define_transaction_abilities(user, params)
    define_individual_credit_account_abilities(user, params)
    define_voucher_meta_abilities(user, params)
    define_statistic_abilities(user, params)
    define_activity_abilities(user, params)
    define_configuration_abilities(user, params)
    define_system_user_abilities(user, params)
    define_platform_account_abilities(user, params)
    define_card_bin_abilities(user, params)
    credit_cashing_application_abilities(user, params)
    define_vouchers_abilities(user, params)
  end

  def define_merchant_store_abilities(user, params)
    if user.has_role? Users::SystemUser::NORMAL_USER
      can :read, Merchant::MerchantStore
    elsif user.has_role? Users::SystemUser::DEPT_MANAGER
      can :manage, Merchant::MerchantStore
    elsif user.has_role? Users::SystemUser::SALES_ASSIST
      can [:basic_edit, :submit_audit], Merchant::MerchantStore
    end
  end

  def define_payment_plan_abilities(user, params)
    if user.has_role? Users::SystemUser::NORMAL_USER
      can :read, Pay::PaymentPlan
    elsif user.has_role? Users::SystemUser::DEPT_MANAGER
      can :manage, Pay::PaymentPlan
    elsif user.has_role? Users::SystemUser::SALES_ASSIST
      can :basic_edit, Pay::PaymentPlan
    end
  end

  def define_marketing_plan_abilities(user, params)
    if user.has_role? Users::SystemUser::NORMAL_USER
      can :read, Merchant::MarketingRule
    elsif user.has_role? Users::SystemUser::DEPT_MANAGER
      can :manage, Merchant::MarketingRule
    elsif user.has_role? Users::SystemUser::SALES_ASSIST
      can :basic_edit, Merchant::MarketingRule
    end
  end

  def define_post_action_abilities(user, params)
    if user.has_role? Users::SystemUser::NORMAL_USER
      can :read, Merchant::PostAction
    elsif user.has_role? Users::SystemUser::DEPT_MANAGER
      can :manage, Merchant::PostAction
    elsif user.has_role? Users::SystemUser::SALES_ASSIST
      can :basic_edit, Merchant::PostAction
    end
  end

  def define_merchant_group_abilities(user, params)
    if user.has_role? Users::SystemUser::NORMAL_USER
      can :read, Merchant::MerchantGroup
    elsif user.has_role? Users::SystemUser::DEPT_MANAGER
      can :manage, Merchant::MerchantGroup
    elsif user.has_role? Users::SystemUser::SALES_ASSIST
      can :basic_edit, Merchant::MerchantGroup
    end
  end

  def define_acquirer_abilities(user, params)
    if user.has_role? Users::SystemUser::NORMAL_USER
      can :read, Merchant::AcquirerOrg
    elsif user.has_role? Users::SystemUser::DEPT_MANAGER
      can :manage, Merchant::AcquirerOrg
    elsif user.has_role? Users::SystemUser::SALES_ASSIST
      can :read, Merchant::AcquirerOrg
    end
  end

  def define_transaction_abilities(user, params)
    if user.has_role? Users::SystemUser::NORMAL_USER
      can :read, Trade::TransactionLog
      can :read, Trade::Transaction
      can :read, Trade::VoucherTransactionLog
      can :read, Trade::TransactionArchive
    elsif user.has_role? Users::SystemUser::DEPT_MANAGER
      can :read, Trade::TransactionLog
      can :read, Trade::Transaction
      can :read, Trade::VoucherTransactionLog
      can :read, Trade::TransactionArchive
    elsif user.has_role? Users::SystemUser::SALES_ASSIST
      can :read, Trade::TransactionLog
      can :read, Trade::Transaction
      can :read, Trade::VoucherTransactionLog
      can :read, Trade::TransactionArchive
    end
  end

  def define_voucher_meta_abilities(user, params)
    if user.has_role? Users::SystemUser::NORMAL_USER
      can :read, Member::VoucherMeta
      can :read, Member::Sequence
      can :read, Member::SequenceNumber
    elsif user.has_role? Users::SystemUser::DEPT_MANAGER
      can :manage, Member::VoucherMeta
      can :manage, Member::Sequence
      can :manage, Member::SequenceNumber
    elsif user.has_role? Users::SystemUser::SALES_ASSIST
      can :basic_edit, Member::VoucherMeta
      can :basic_edit, Member::Sequence
      can :basic_edit, Member::SequenceNumber
    end
  end

  def define_statistic_abilities(user, params)
    can :read, :statistic
  end

  def define_individual_credit_account_abilities(user, params)
    can :read, Member::IndividualCreditAccount
    can :read, Member::BankCard
  end

  def define_vouchers_abilities(user, params)
    if user.has_role? Users::SystemUser::NORMAL_USER
      can :read, Member::Voucher
    elsif user.has_role? Users::SystemUser::DEPT_MANAGER
      can :manage, Member::Voucher
    elsif user.has_role? Users::SystemUser::SALES_ASSIST
      can :read, Member::Voucher
    end
  end

  def credit_cashing_application_abilities(user, params)
    if user.has_role? Users::SystemUser::DEPT_MANAGER
      can :manage, Member::CreditCashingApplication
    end
  end

  def define_activity_abilities(user, params)
    can :read, System::ActivityLog
  end

  def define_configuration_abilities(user, params)
    if user.has_role? Users::SystemUser::DEPT_MANAGER
      can :read, System::Configuration
    end
  end

  def define_system_user_abilities(user, params)
    can :pwd, Users::SystemUser
    can :reset_password, Users::SystemUser
    if user.has_role? Users::SystemUser::DEPT_MANAGER
      can :read, Users::SystemUser
    end
  end

  def define_card_bin_abilities(user, params)
    if user.has_role? Users::SystemUser::DEPT_MANAGER
      can :read, Bank::CardBin
    elsif user.has_role? Users::SystemUser::SALES_ASSIST
      can :read, Bank::CardBin
    end
  end

  def define_platform_account_abilities(user, params)
  end
end

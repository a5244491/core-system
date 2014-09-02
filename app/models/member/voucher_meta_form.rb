require 'reform/form/coercion'
class Member::VoucherMetaForm < Reform::Form
  include Coercion
  include FormFieldsConversion
  property :aliases, type: String
  property :limit_per_account_on, empty: true
  property :limit_per_account, type: Integer
  property :applicable_target_name, type: String, empty: true
  property :applicable_type, type: Integer
  property :money_condition
  property :denomination
  property :initial_amount_on, empty: true
  property :initial_amount, type: Integer
  property :valid_till
  property :valid_from
  property :remark, type: String
  property :issuer_type, type: Integer
  property :issuer_name, type: String
  property :issuer_identifier, type: String
  property :settler_type, type: Integer
  property :settler_name, type: String
  property :settler_identifier, type: String
  property :merchant_store
  property :merchant_group

  cent_to_yuan_fields :money_condition, :denomination
  utc_to_local_fields :valid_from, :valid_till

  def limit_per_account_on
    if super.nil?
      self.limit_per_account != Member::VoucherMeta::DEFAULT_LIMIT_PER_ACCOUNT && !self.limit_per_account.nil?
    else
      super
    end
  end

  alias_method :real_initial_amount_on, :initial_amount_on

  def initial_amount_on
    if super.nil?
      self.initial_amount != Member::VoucherMeta::DEFAULT_INITIAL_AMOUNT && !self.initial_amount.nil?
    else
      super
    end
  end

  def initial_amount
    super == Member::VoucherMeta::DEFAULT_INITIAL_AMOUNT ? nil : super
  end

  def limit_per_account
    super == Member::VoucherMeta::DEFAULT_LIMIT_PER_ACCOUNT ? nil : super
  end

  def applicable_target_name
    if super.blank?
      case self.applicable_type
        when Member::VoucherMeta::SINGLE_STORE
          self.merchant_store.try(:name)
        when Member::VoucherMeta::STORE_GROUP
          self.merchant_group.try(:name)
      end
    else
      super
    end
  end

  def validate(params)
    super(params)
    normalize_params
  end

  private
  def normalize_params
    unless self.limit_per_account_on.to_bool
      self.limit_per_account = Member::VoucherMeta::DEFAULT_LIMIT_PER_ACCOUNT
    end

    unless self.initial_amount_on.to_bool
      self.initial_amount = Member::VoucherMeta::DEFAULT_INITIAL_AMOUNT
    end

    case self.applicable_type
      when Member::VoucherMeta::SINGLE_STORE
        merchant = Merchant::MerchantStore.where(name: self.applicable_target_name).first unless self.applicable_target_name.blank?
        self.errors['适用对象'] << "商户#{self.applicable_target_name}不存在" if merchant.nil?
        self.merchant_store = merchant
      when Member::VoucherMeta::STORE_GROUP
        group = Merchant::MerchantGroup.where(name: self.applicable_target_name).first unless self.applicable_target_name.blank?
        self.errors['适用对象'] << "商户群组#{self.applicable_target_name}不存在" if group.nil?
        self.merchant_group = group
    end

    self.issuer_identifier = fetch_identifier(self.issuer_type, issuer_name, '发行方')
    self.settler_identifier = fetch_identifier(self.settler_type, settler_name)
    self.errors.empty?
  end

  def fetch_identifier(type, name, error_tag = '结算方')
    case type
      when Member::VoucherMeta::BANK, Member::VoucherMeta::PARTNER
        name
      when Member::VoucherMeta::MERCHANT
        merchant = Merchant::MerchantStore.where(name: name).first unless name.blank?
        self.errors[error_tag] << "商户#{name}不存在" if merchant.nil?
        merchant.try(:merchant_number)
      when Member::VoucherMeta::SELF
        'platform'
    end
  end
end
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

  alias_method :real_limit_per_account_on, :limit_per_account_on
  def limit_per_account_on
    self.limit_per_account == Member::VoucherMeta::DEFAULT_LIMIT_PER_ACCOUNT
  end

  alias_method :real_initial_amount_on, :initial_amount_on
  def initial_amount_on
    self.initial_amount == Member::VoucherMeta::DEFAULT_INITIAL_AMOUNT
  end

  def validate(params)
    super(params)
    normalize_params
  end

  private
  def normalize_params
    if self.real_limit_per_account_on.to_bool
      self.limit_per_account = Member::VoucherMeta::DEFAULT_LIMIT_PER_ACCOUNT
    end
    if self.real_initial_amount_on.to_bool
      self.initial_amount = Member::VoucherMeta::DEFAULT_INITIAL_AMOUNT
    end

    case self.applicable_type
      when Member::VoucherMeta::SINGLE_STORE
        merchant = Merchant::MerchantStore.where(name: self.applicable_target_name).first unless self.applicable_target_name.blank?
        self.errors['适用对象'] << "商户#{self.applicable_target_name}不存在" if merchant.nil?
        self.merchant_store = merchant
      when Member::VoucherMeta::STORE_GROUP
        group = Merchant::MerchantGroup.where(name: self.applicable_target_name).first unless self.applicable_target_name.blank?
        self.errors[:merchant_group] << "商户群组#{self.applicable_target_name}不存在" if group.nil?
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
    end
  end
end
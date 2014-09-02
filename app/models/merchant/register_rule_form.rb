class Merchant::RegisterRuleForm < Reform::Form
  include FormFieldsConversion
  property :valid_till
  property :valid_from
  property :merchant_store

  utc_to_local_fields :valid_till, :valid_from

end
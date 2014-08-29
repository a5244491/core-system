require 'reform/form/coercion'
class Merchant::CreditBackForm < Reform::Form
  include Coercion
  include FormFieldsConversion
  property :voucher_status, type: Integer, default: Pay::PaymentPlan::ACCEPT_NONE
  property :merchant_rate
  property :referer_rate
  property :customer_rate
  property :merchant_store
  property :valid_from, default: Time.now
  property :valid_till, default: 10.years.from_now

  percentage_to_decimal_fields :merchant_rate, :referer_rate, :customer_rate
  utc_to_local_fields :valid_from, :valid_till
end
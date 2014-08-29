require 'reform/form/coercion'
class Merchant::NonePaymentPlanForm < Reform::Form
  include Coercion
  include FormFieldsConversion
  property :voucher_status, type: Integer, default: Pay::PaymentPlan::ACCEPT_NONE
  property :merchant_store
  property :valid_from, default: Time.now
  property :valid_till, default: 10.years.from_now
  utc_to_local_fields :valid_from, :valid_till
end
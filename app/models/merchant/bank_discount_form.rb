require 'reform/form/coercion'
class Merchant::BankDiscountForm < Reform::Form
  include Coercion
  include FormFieldsConversion
  property :user_type, type: Integer
  property :bank_name, type: String
  property :voucher_status, type: Integer, default: Pay::PaymentPlan::ACCEPT_NONE
  property :merchant_rate
  property :referer_rate
  property :discount_rate, default: 0
  property :minimal_money_amount, default: 0
  property :discount_amount, default: 0
  property :merchant_store
  property :valid_from, default: Time.now
  property :valid_till, default: 10.years.from_now

  percentage_to_decimal_fields :merchant_rate, :referer_rate, :discount_rate
  cent_to_yuan_fields :discount_amount, :minimal_money_amount
  utc_to_local_fields :valid_from, :valid_till
end
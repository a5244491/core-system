FactoryGirl.define do
  factory :merchant_group, class: Merchant::MerchantGroup do
     name 'test_group'
     ignore do
       stores []
     end
     before :create do |merchant_group, evaluator|
       evaluator.stores.each do |store|
         merchant_group.merchant_stores << store
       end
     end
  end
end
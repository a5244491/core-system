module FormFieldsConversion
  extend ActiveSupport::Concern
  module ClassMethods
    def percentage_to_decimal_fields(*names)
      names.each do |name|
        define_method(name) do
          super.to_f * 100 unless super.blank?
        end
        define_method("#{name}=") do |value|
          super(value.to_f / 100) unless value.blank?
        end
      end
    end

    def cent_to_yuan_fields(*names)
      names.each do |name|
        define_method(name) do
          super.to_i / 100.0 unless super.blank?
        end
        define_method("#{name}=") do |value|
          super((value.to_f * 100).to_i) unless value.blank?
        end
      end
    end
  end
end
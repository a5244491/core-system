module Member
  class Sequence < ActiveRecord::Base
    validates_uniqueness_of :name
    has_many :sequence_numbers, dependent: :destroy
    has_one :voucher_meta

    def allocate_sequence_number
      self.with_lock do
        selected_number = sequence_numbers.where(used: false).order(number: :asc).limit(1).first
        unless selected_number.nil?
          selected_number.used = true
          selected_number.save!
          selected_number.number
        else
          nil
        end
      end
    end
  end
end
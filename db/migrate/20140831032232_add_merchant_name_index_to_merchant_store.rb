class AddMerchantNameIndexToMerchantStore < ActiveRecord::Migration
  def change
    change_table(:merchant_stores) do |t|
      t.index :name, unique: true
    end
  end
end

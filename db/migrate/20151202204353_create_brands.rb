class CreateBrands < ActiveRecord::Migration
  def change
    create_table :brands do |t|
      t.string :name
      t.integer :pricing_tier
      t.timestamps null: false
    end
  end
end

class AddIndexToTable < ActiveRecord::Migration
  def change
    add_index :tables, :brand_name
    add_index :tables, :price
  end
end

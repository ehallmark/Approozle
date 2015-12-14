class AddPriceToTables < ActiveRecord::Migration
  def change
    add_column :tables, :price, :float
  end
end

class AddBrandNameIndexToTables < ActiveRecord::Migration
  def change
    add_column :tables, :brand_name_index, :integer
  end
end

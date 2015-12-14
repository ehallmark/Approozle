class AddBrandIdToTables < ActiveRecord::Migration
  def change
    add_column :tables, :brand_id, :integer
  end
end

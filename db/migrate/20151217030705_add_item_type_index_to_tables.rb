class AddItemTypeIndexToTables < ActiveRecord::Migration
  def change
    add_column :tables, :item_type_index, :integer
  end
end

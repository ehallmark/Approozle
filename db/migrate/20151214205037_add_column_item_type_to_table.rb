class AddColumnItemTypeToTable < ActiveRecord::Migration
  def change
    add_column :tables, :item_type, :string
  end
end

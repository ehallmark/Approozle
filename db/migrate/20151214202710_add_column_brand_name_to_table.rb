class AddColumnBrandNameToTable < ActiveRecord::Migration
  def change
    add_column :tables, :brand_name, :string
  end
end

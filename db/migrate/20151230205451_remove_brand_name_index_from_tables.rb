class RemoveBrandNameIndexFromTables < ActiveRecord::Migration
  def change
    remove_column :tables, :brand_name_index, :integer
    remove_column :tables, :size, :string
    remove_column :tables, :height, :float
    remove_column :tables, :width, :float
    remove_column :tables, :length, :float
    remove_column :tables, :shape, :string
    remove_column :tables, :detailing, :string
  end
end

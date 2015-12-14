class RemoveBrandFromTables < ActiveRecord::Migration
  def change
    remove_column :tables, :brand, :string
  end
end

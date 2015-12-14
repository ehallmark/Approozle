class CreateTable < ActiveRecord::Migration
  def change
    create_table :tables do |t|
      t.string :material
      t.string :detailing
      t.string :brand
      t.string :shape
      t.float :length
      t.float :width
      t.float :height
      t.string :size
      t.timestamps null: false
    end
  end
end

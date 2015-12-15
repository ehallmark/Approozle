#class CreateTable < ActiveRecord::Migration
#  def change
#    create_table :tables do |t|
#      t.string :material
#      t.string :detailing
#      t.string :brand_name
#      t.string :shape
#      t.float :length
#      t.float :width
#      t.float :height
#      t.string :size
#      t.timestamps null: false
#    end
#  end
#end

class Table < ActiveRecord::Base
  #belongs_to :brand
  #accepts_nested_attributes_for :brand
  def self.dining
    self.where("upper(item_type) = 'DINING TABLE'")
  end
end

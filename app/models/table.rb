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
  include PgSearch
  #belongs_to :brand
  #accepts_nested_attributes_for :brand
  pg_search_scope :search_query, :against => [[:name,'A'],[:brand_name,'B'],[:item_type,'B'],[:material,'C']]
  scope :item_type, lambda {|item| where("upper(item_type) = '#{item.upcase}'") }
  scope :dining_table, lambda { where("upper(item_type)='DINING TABLE'") }
  scope :pub_table, lambda { where("upper(item_type)='PUB TABLE'") }
  scope :sofa_table, lambda { where("upper(item_type)='SOFA TABLE'") }
  scope :console_table, lambda { where("upper(item_type)='CONSOLE TABLE'") }
  scope :end_table, lambda { where("upper(item_type)='END TABLE'") }
  scope :buffet_table, lambda { where("upper(item_type)='BUFFET TABLE'") }
  scope :bistro_table, lambda { where("upper(item_type)='BISTRO TABLE'") }
  scope :occasional_table, lambda { where("upper(item_type)='OCCASIONAL TABLE'") }
  scope :sideboard, lambda { where("upper(item_type)='SIDEBOARD'") }
  scope :sorted_by, lambda { |sort_option|
    direction = (sort_option =~ /desc$/) ? 'desc' : 'asc'
    case sort_option.to_s
    when /^name/
      order("LOWER(tables.name) #{ direction } NULLS LAST")
    when /^brand_name_index/
      order("LOWER(tables.brand_name_index) #{ direction } NULLS LAST")
    when /^brand_name/
      order("LOWER(tables.brand_name) #{ direction } NULLS LAST")
    when /^item_type/
      order("LOWER(tables.item_type) #{ direction } NULLS LAST")
    when /^material/
      order("LOWER(tables.material) #{ direction } NULLS LAST")
    else
      raise(ArgumentError, "Invalid sort option: #{ sort_option.inspect }")
    end
  }
  filterrific(
    available_filters: [
      :sorted_by,
      :search_query,
      :item_type
    ]
  )
  
end

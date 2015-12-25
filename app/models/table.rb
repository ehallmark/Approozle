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
  before_validation :capitalize_attributes
  validate :validate_table
  
  pg_search_scope :search_query, :against => [[:name,'A'],[:brand_name,'B'],[:item_type,'B'],[:material,'C']]
  scope :item_type, lambda {|item| where("upper(item_type) = '#{item.upcase}'") }
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
  private
  def capitalize_attributes
    write_attribute(:name,self.name.upcase) if self.name != self.name.upcase
    write_attribute(:item_type,self.item_type.upcase) if self.item_type.present? and self.item_type != self.item_type.upcase
    write_attribute(:brand_name,self.brand_name.upcase) if self.brand_name.present? and self.brand_name != self.brand_name.upcase
    write_attribute(:material,self.material.upcase) if self.material.present? and self.material != self.material.upcase
  end
  
  def validate_table
    #wrong stuff blank
    errors.add(:name_blank, "Name not present") unless self.name.present?
    errors.add(:brand_name_blank, "Brand_name not present") unless self.brand_name.present?
    errors.add(:item_type_blank, "Item_type not present") unless self.item_type.present?
    #bad price
    errors.add(:invalid_price, "Invalid price") if self.price.blank? or self.price < 20
    #stuff not in all caps
    errors.add(:brand_name_not_capitalized, "Brand_name not capitalized") unless (self.brand_name || "")==(self.brand_name || "").upcase
    errors.add(:name_not_capitalized, "Name not capitalized") unless (self.name || "")==(self.name || "").upcase
    errors.add(:item_type_not_capitalized, "Item_type not capitalized") unless (self.item_type || "")==(self.item_type || "").upcase
    errors.add(:material_not_capitalized, "Material not capitalized") unless (self.material || "")==(self.material || "").upcase
    #validate duplicates
    errors.add(:duplicate_record_found, "Duplicate record found") if Table.where(
      price: self.price,
      material: self.material,
      brand_name: self.brand_name,
      item_type: self.item_type
    ).exists?
    #is part of a set or a toy
    errors.add(:bad_keywords, "Found bad keywords") if (self.name.starts_with?("SET ") or self.name.include?(" SET ") or self.name.include? ("(SET") or self.name.include?("SET:") or self.name.include?(" TOY ") or self.name.include?("MINIATURE"))
    
  end
  
end

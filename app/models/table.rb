#class CreateTable < ActiveRecoritemd::Migration
#  def change
#    create_table :tables do |t|
#      t.string :material
#      t.string :brand_name
#      t.timestamps null: false
#    end
#  end
#end

class Table < ActiveRecord::Base

  #belongs_to :brand
  #accepts_nested_attributes_for :brand
  before_validation :capitalize_attributes
  validate :validate_table
  attr_accessor :optional_search 

  scope :search_query, lambda {|q| where("name like upper('%#{q}%') or item_type like upper('%#{q}%') or material like upper('%#{q}%') or brand_name like upper('%#{q}%')") }
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
  
  def keywords
    self.name.split(" ")
  end
  
  def self.badwords
    ["TOY","TOYS","MINIATURE","LAMPS","DOLLS","SET","SETS","DOLL","DOLLHOUSE"]
  end
  
  def has_badword
    Table.badwords.each{|word| return true if self.keywords.include?(word)}
    return false
  end
  
  private
  def capitalize_attributes
    write_attribute(:name,self.name.upcase.gsub(/[^0-9A-Z ]/i,'').strip) if self.name != self.name.upcase.gsub(/[^0-9A-Z ]/i,'').strip
    write_attribute(:item_type,self.item_type.upcase.gsub(/[^0-9A-Z ]/i,'').strip) if self.item_type.present? and self.item_type != self.item_type.upcase.gsub(/[^0-9A-Z ]/i,'').strip
    write_attribute(:brand_name,self.brand_name.upcase.gsub(/[^0-9A-Z ]/i,'').strip) if self.brand_name.present? and self.brand_name != self.brand_name.upcase.gsub(/[^0-9A-Z ]/i,'').strip
    write_attribute(:material,self.material.upcase.gsub(/[^0-9A-Z ]/i,'').strip) if self.material.present? and self.material != self.material.upcase.gsub(/[^0-9A-Z ]/i,'').strip
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
    duplicate_table_ids = Table.where(
      price: self.price,
      material: self.material,
      brand_name: self.brand_name,
      item_type: self.item_type
    ).pluck(:id)
    errors.add(:duplicate_record_found, "Duplicate record found") if (duplicate_table_ids-[self.id]).present?
    #is part of a set or a toy
    errors.add(:bad_keywords, "Found bad keywords") if self.has_badword
    
  end
  
end

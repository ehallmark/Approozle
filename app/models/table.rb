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
  
  def self.similar_brand_name_hash
    {
      "LAZBOY"=> ["LAZYBOY", "LAZ BOY", "LA Z BOY"]
    
    }
  end
  
  def self.similar_item_type_hash
    {
      
    }
  end
  
  def self.similar_search_options_hash
    {
    }
  end
  
  def self.similar_material_hash
    {
    }
  end
  
  def keywords
    self.name.split(" ")
  end
  
  def self.badwords
    ["TOY","TOYS","MINIATURE","LAMPS","DOLLS","SET","SETS","DOLL","DOLLHOUSE"]
  end
  
  def self.badwords_by_item_type
    {
      "BENCH" => ["PICNIC TABLE", "BENCHES"]
    }
  end
  
  def has_badword
    Table.badwords.each{|word| return true if self.keywords.include?(word)}
    (Table.badwords_by_item_type[self.item_type] || []).each{|word| return true if self.keywords.include?(word) }
    return false
  end
  
  def self.used_brand_name_hash
      {
        "AMERICAN DREW"=>0.6,
        "BAKER"=>0.4,
        "BALLARD DESIGNS"=>0.6,
        "BASSETT"=>0.6,
        "BERNHARDT"=>0.5,
        "BORKHOLDER"=>0.5,
        "BROYHILL"=> 0.6,
        "CALLIGARIS"=> 0.5,
        "CENTURY"=>0.5,
        "CHARLESTON FORGE"=>0.5,
        "COASTER"=>0.8,
        "CRATE & BARREL"=>0.6,
        "DANIA"=> 0.6,
        "DINEC"=>0.6,
        "DREXEL"=>0.5,
        "DREXEL HERITAGE"=>0.5,
        "DURHAM"=>0.6,
        "EKORNES"=>0.5,
        "ETHAN ALLEN"=>0.5,
        "FAIRFIELD CHAIR"=>0.5,
        "FAIRFIELD"=>0.5,
        "FLEXSTEEL"=>0.5,
        "GRANGE"=>0.6,
        "GUY CHADDOCK"=>0.4,
        "HABERSHAM"=>0.4,
        "HANCOCK & MOORE"=>0.5,
        "HARDEN"=>0.5,
        "HEKMAN"=>0.5,
        "HENKEL HARRIS"=>0.4,
        "HENREDON"=>0.5,
        "HERITAGE"=>0.5,
        "HICKORY"=>0.4,
        "HICKORY CHAIR"=>0.4,
        "HICKORY WHITE"=>0.4,
        "HOOKER"=>0.5,
        "IKEA"=>0.7,
        "JASPER"=>0.6,
        "JOINERY"=>0.6,
        "KINCAID"=>0.6,
        "KITCHEN KABOODLE"=>0.7,
        "KNOB CREEK"=>0.6,
        "KOHLS"=>0.7,
        "LA BARGE"=>0.4,
        "LANE"=>0.6,
        "LAZBOY"=>0.6,
        "LEXINGTON"=>0.5,
        "LILLIAN AUGUST"=>0.4,
        "MAITLAND SMITH"=>0.4,
        "MARGE CARSON"=> 0.4,
        "MCGUIRE"=>0.4,
        "MITCHELL GOLD"=>0.5,
        "NATUZZI"=>0.4,
        "NICHOLS & STONE"=>0.6,
        "NORWALK"=>0.6,
        "PENNSYLVANIA HOUSE"=>0.4,
        "PIER 1"=>0.7,
        "POTERRY BARN"=>0.6,
        "PULASKI"=>0.5,
        "RESTORATION HARDWARE"=>0.6,
        "ROCHE BOBOIS"=>0.4,
        "ROMWEBER"=>0.6,
        "ROWE"=>0.6,
        "SALOOM"=>0.6,
        "SCHNADIG"=>0.5,
        "SHERRILL"=>0.5,
        "SITCOM"=>0.8,
        "SKOVBY"=>0.5,
        "STANLEY"=>0.5,
        "STICKLEY"=>0.5,
        "SWAIM"=>0.4,
        "TARGET"=>0.7,
        "THOMASVILLE"=>0.5,
        "TRICA"=>0.7,
        "VANGUARD"=>0.5,
        "WALMART"=>0.7,
        "WEST ELM"=>0.7,
        "WILLIAMS SONOMA"=>0.5,
        "WOODBRIDGE"=>0.7
      }
  end
  
  def self.used_item_type_hash
    {
      "DINING TABLE"=>0.4,
      "DINING CHAIR"=>0.4,
      "PUB TABLE"=>0.4,
      "BISTRO TABLE"=>0.4,
      "BAR STOOL"=>0.4,
      "CHINA HUTCH"=>0.7,
      "CHINA CLOSET"=>0.7,
      "BUFFET TABLE"=>0.6,
      "BUFFET"=>0.6,
      "SIDEBOARD"=>0.5,
      "SERVER"=>0.6,
      "BAR"=>0.5,
      "BAR TABLE"=>0.5,
      "SIDEBOARD TABLE"=>0.5,
      "DISPLAY CASE"=>0.6,
      "CURIO"=>0.6,
      "ETAGERE"=>0.4,
      "CONSOLE"=>0.5,
      "PLATFORM BED"=>0.4,
      "CAPTAIN BED"=>0.5,
      "PIER BED"=>0.6,
      "4 POSTER BED"=>0.4,
      "CANOPY BED"=>0.4,
      "TRUNDLE BED"=>0.5,
      "DAY BED"=>0.6,
      "FUTON"=>0.4,
      "DRESSER"=>0.4,
      "CHEST"=>0.4,
      "CHEST ON CHEST"=>0.5,
      "GENTLEMAN CHEST"=>0.5,
      "LINGERIE CHEST"=>0.4,
      "HIGH BOY"=>0.7,
      "NIGHTSTAND"=>0.4,
      "ARMOIRE"=>0.7,
      "VANITY TABLE"=>0.5,
      "SOFA"=>0.4,
      "LOVESEAT"=>0.4,
      "CLUB CHAIR"=>0.4,
      "CHAIR"=>0.4,
      "DESK CHAIR"=>0.4,
      "HALF CHAIR"=>0.4,
      "GLIDER CHAIR"=>0.4,
      "MASSAGE CHAIR"=>0.3,
      "MASSAGE RECLINER CHAIR"=>0.3,
      "OCCASIONAL CHAIR"=>0.5,
      "RECLINER CHAIR"=>0.4,
      "ROCKER CHAIR"=>0.5,
      "ROCKER RECLINER CHAIR"=>0.4,
      "SLEEPER CHAIR"=>0.6,
      "SWIVEL CHAIR"=>0.4,
      "SWIVEL RECLINER CHAIR"=>0.4,
      "SWIVEL ROCKER CHAIR"=>0.4,
      "SWIVEL ROCKER RECLINER CHAIR"=>0.4,
      "WINGBACK CHAIR"=>0.5,
      "ZERO GRAVITY CHAIR"=>0.4,
      "CHAISE LOUNGE"=>0.5,
      "SETTEE"=>0.6,
      "BENCH"=>0.5,
      "RECLINER SOFA"=>0.4,
      "RECLINER LOVESEAT"=>0.4,
      "SLEEPER SOFA"=>0.4,
      "SLEEPER LOVESEAT"=>0.4,
      "SECTIONAL"=>0.5,
      "SECTIONAL WITH SLEEPER"=>0.4,
      "SECTIONAL WITH RECLINER"=>0.4,
      "OTTOMAN"=>0.4,
      "COFFEE TABLE"=>0.4,
      "END TABLE"=>0.4,
      "SOFA TABLE"=>0.5,
      "OCCASIONAL TABLE"=>0.5,
      "TV STAND"=>0.4,
      "TV CONSOLE"=>0.5,
      "ENTERTAINMENT CENTER"=>0.7,
      "WALL UNIT"=>0.7,
      "SHELF UNIT"=>0.4,
      "DESK"=>0.5,
      "STUDENT DESK"=>0.5,
      "COMPUTER DESK"=>0.7,
      "WRITING DESK"=>0.4,
      "EXECUTIVE DESK"=>0.6,
      "SECRETARY"=>0.7,
      "OFFICE CHAIR"=>0.4,
      "CABINET"=>0.4,
      "COMPUTER ARMOIRE"=>0.7,
      "CREDENZA"=>0.6,
      "BOOKCASE"=>0.4
    }
  end
  
  def self.all_item_types
    Table.used_item_type_hash.keys.sort
  end

  def self.all_brand_names
    Table.used_brand_name_hash.keys.sort
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

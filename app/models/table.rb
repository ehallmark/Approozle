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
require 'rinruby'
include PgSearch

  pg_search_scope :with_search, :against => :name #,
     #                           :using => {
     #                               :tsearch => {:any_word => true}
      #                            }
  
  #belongs_to :brand
  #accepts_nested_attributes_for :brand
  before_validation :capitalize_attributes
  validate :validate_table
  attr_accessor :optional_search, :seat_or_cushion, :furniture_style, :fabric_color, :fabric_pattern, :fabric_type, :backrest_style, :finish_type, :material, :material_of_shelves, :material_of_base, :material_of_insets, :carved_detailing, :nailhead_trimming
  scope :search_query, lambda {|q| where("name like upper('%#{q}%') or item_type like upper('%#{q}%') or material like upper('%#{q}%') or brand_name like upper('%#{q}%')") }
  scope :item_type, lambda {|item| where("upper(item_type) = '#{item.upcase}'") }
  scope :sorted_by, lambda { |sort_option|
    direction = (sort_option =~ /desc$/) ? 'desc' : 'asc'
    case sort_option.to_s
    when /^name/
      order("LOWER(tables.name) #{ direction } NULLS LAST")
    when /^brand_name_index/
      order("tables.brand_name_index #{ direction } NULLS LAST")
    when /^item_type_index/
      order("tables.item_type_index #{ direction } NULLS LAST")
    when /^brand_name/
      order("LOWER(tables.brand_name) #{ direction } NULLS LAST")
    when /^item_type/
      order("LOWER(tables.item_type) #{ direction } NULLS LAST")
    when /^price/
      order("tables.price #{ direction } NULLS LAST")
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
  
  def self.standardized_item_types
    new_hash = {}
    Table.similar_item_type_hash.each {|k,val| val.each{|v| new_hash[v]=k unless Table.all_item_types.include? v } }
    return new_hash
  end
  
  def self.form_type
    {
      "DINING TABLE"=>"D",
      "DINING CHAIR"=>"C",
      "PUB TABLE"=>"D",
      "BISTRO TABLE"=>"D",
      "BAR STOOL"=>"B",
      "CHINA HUTCH"=>"",
      "CHINA CLOSET"=>"",
      "BUFFET"=>"D",
      "SIDEBOARD"=>"D",
      "SERVER"=>"A",
      "BAR"=>"D",
      "BAR TABLE"=>"",
      "DISPLAY CASE"=>"",
      "CURIO"=>"",
      "ETAGERE"=>"",
      "CONSOLE"=>"D",
      "PLATFORM BED"=>"C",
      "CAPTAIN BED"=>"C",
      "PIER BED"=>"C",
      "4 POSTER BED"=>"C",
      "CANOPY BED"=>"C",
      "TRUNDLE BED"=>"C",
      "DAY BED"=>"C",
      "FUTON"=>"A",
      "DRESSER"=>"A",
      "CHEST"=>"A",
      "CHEST ON CHEST"=>"A",
      "GENTLEMAN CHEST"=>"A",
      "LINGERIE CHEST"=>"A",
      "HIGH BOY"=>"A",
      "NIGHTSTAND"=>"A",
      "ARMOIRE"=>"A",
      "VANITY TABLE"=>"A",
      "SOFA"=>"",
      "LOVESEAT"=>"",
      "CLUB CHAIR"=>"B",
      "CHAIR"=>"B",
      "DESK CHAIR"=>"B",
      "HALF CHAIR"=>"B",
      "GLIDER CHAIR"=>"B",
      "MASSAGE CHAIR"=>"B",
      "MASSAGE RECLINER CHAIR"=>"B",
      "OCCASIONAL CHAIR"=>"B",
      "RECLINER CHAIR"=>"B",
      "ROCKER CHAIR"=>"B",
      "ROCKER RECLINER CHAIR"=>"B",
      "SLEEPER CHAIR"=>"B",
      "SWIVEL CHAIR"=>"B",
      "SWIVEL RECLINER CHAIR"=>"B",
      "SWIVEL ROCKER CHAIR"=>"B",
      "SWIVEL ROCKER RECLINER CHAIR"=>"B",
      "WINGBACK CHAIR"=>"B",
      "ZERO GRAVITY CHAIR"=>"B",
      "CHAISE LOUNGE"=>"B",
      "SETTEE"=>"",
      "BENCH"=>"",
      "RECLINER SOFA"=>"",
      "RECLINER LOVESEAT"=>"",
      "SLEEPER SOFA"=>"",
      "SLEEPER LOVESEAT"=>"",
      "SECTIONAL"=>"",
      "SECTIONAL WITH SLEEPER"=>"",
      "SECTIONAL WITH RECLINER"=>"",
      "OTTOMAN"=>"",
      "COFFEE TABLE"=>"D",
      "END TABLE"=>"D",
      "SOFA TABLE"=>"D",
      "OCCASIONAL TABLE"=>"D",
      "TV STAND"=>"",
      "TV CONSOLE"=>"",
      "ENTERTAINMENT CENTER"=>"",
      "WALL UNIT"=>"",
      "SHELF UNIT"=>"",
      "DESK"=>"A",
      "STUDENT DESK"=>"A",
      "COMPUTER DESK"=>"A",
      "WRITING DESK"=>"A",
      "EXECUTIVE DESK"=>"A",
      "SECRETARY"=>"",
      "OFFICE CHAIR"=>"B",
      "CABINET"=>"A",
      "COMPUTER ARMOIRE"=>"A",
      "CREDENZA"=>"A",
      "BOOKCASE"=>""
    }
  end
  
  def self.standardized_brand_names
    {
      "KOHLS"=>"KOHL'S",
      "KOHL S"=>"KOHL'S",
      "KOHL"=>"KOHL'S",
      "CRATE  BARREL"=>"CRATE & BARREL",
      "CRATE BARREL"=>"CRATE & BARREL",
      "HANCOCK MOORE"=>"HANCOCK & MOORE",
      "HANCOCK  MOORE"=>"HANCOCK & MOORE",
      "WALMART"=>"WAL-MART",
      "LAZBOY"=>"LA Z BOY",
      "LAZYBOY"=>"LA Z BOY"
    }
  end
  
  def self.similar_brand_name_hash
    {
      "LAZBOY"=>["LAZYBOY", "LAZ BOY", "LA Z BOY"],
      "LA Z BOY"=>["LAZYBOY","LAZBOY"],
      "KOHLS"=>["KOHL S","KOHL"],
    
    }
  end
  
  def self.similar_item_type_hash
    {
      "DINING TABLE"=>["KITCHEN TABLE","DINNER TABLE","DINING ROOM TABLE","PUB TABLE","BISTRO TABLE"],
      "DINING CHAIR"=>["EATING CHAIR","DINNER CHAIR","DINING ROOM CHAIR"],
      "PUB TABLE"=>["KITCHEN TABLE","DINNER TABLE","DINING ROOM TABLE","COUNTER HEIGHT TABLE","BAR HEIGHT TABLE","BISTRO TABLE","DINING TABLE"],
      "BISTRO TABLE"=>["KITCHEN TABLE","DINNER TABLE","DINING ROOM TABLE","COUNTER HEIGHT TABLE","BAR HEIGHT TABLE","PUB TABLE","DINING TABLE"],
      "BAR STOOL"=>["STOOL","COUNTER STOOL"],
      "CHINA HUTCH"=>["HUTCH","DISPLAY CABINET","CHINA CLOSET"],
      "CHINA CLOSET"=>["HUTCH","DISPLAY CABINET","CHINA HUTCH"],
      "BUFFET"=>["STORAGE CABINET","DINNER WARE CABINET","DINNERWARE CABINET"],
      "SIDEBOARD"=>["WALL TABLE","SIDEBOARD TABLE","BUFFET TABLE","DINING ROOM WALL TABLE"],
      "SERVER"=>["SERVER TABLE","BAR","BAR TABLE","MOBILE BAR"],
      "BAR"=>["SERVER","SERVER TABLE","BAR TABLE","MOBILE BAR"],
      "DISPLAY CASE"=>["HUTCH","DISPLAY CABINET","COLLECTIBLE CASE","ACCESSORY CASE","CURIO"],
      "CURIO"=>["DISPLAY CABINET","COLLECTIBLE CASE","ACCESSORY CASE","DISPLAY CASE"],
      "ETAGERE"=>["SHELF","COLLECTIBLE SHELF","ACCESSORY SHELF","BOOKCASE","BOOKSHELF"],
      "CONSOLE"=>["WALL TABLE","CONSOLE TABLE","ENTRYWAY TABLE","HALLWAY TABLE"],
      "PLATFORM BED"=>["SCANDINAVIAN BED","LOW BED","BED WITHOUT BOX SPRING"],
      "CAPTAIN BED"=>["STORAGE BED","BED WITH DRAWERS"],
      "PIER BED"=>["STORAGE BED","BED WITH DRAWERS","BED AND NIGHTSTAND","BAD AND ARMOIRE"],
      "4 POSTER BED"=>["CANOPY BED","TRADITIONAL BED","FOUR POSTER BED"],
      "CANOPY BED"=>["4 POSTER BED","TRADITIONAL BED"],
      "TRUNDLE BED"=>["BED WITH GUEST MATTRESS","BED WITH PULL OUT MATTRESS"],
      "DAY BED"=>["TRUNDLE BED","SOFA BED","FUTON"],
      "FUTON"=>["PULL OUT BED","SOFA BED","DAY BED"],
      "DRESSER"=>["CHESTT","CHEST OF DRAWERS"],
      "CHEST"=>["DRESSER","CHEST OF DRAWERS"],
      "CHEST ON CHEST"=>["DRESSER","CHEST","CHEST OF DRAWERS"],
      "GENTLEMAN CHEST"=>["DRESSER","CHEST","CHEST OF DRAWERS"],
      "LINGERIE CHEST"=>["DRESSER","CHEST","CHEST OF DRAWERS"],
      "HIGH BOY"=>["DRESSER","CHEST","CHEST OF DRAWERS","FORMAL CHEST"],
      "NIGHTSTAND"=>["BED SIDE TABLE"],
      "ARMOIRE"=>["WARDROBE","CLOSET","CLOTHING CABINET"],
      "VANITY TABLE"=>["MAKEUP TABLE","MAKE UP TABLE","POWDER TABLE"],
      "SOFA"=>["COUCH","DAVENPORT","SETTEE"],
      "LOVESEAT"=>["COUCH","DAVENPORT","SETTEE"],
      "CLUB CHAIR"=>["CHAIR","SOFA CHAIR","LIVING ROOM CHAIR"],
      "CHAIR"=>["SOFA CHAIR","LIVING ROOM CHAIR","OVERSIDED CHAIR"],
      "GLIDER CHAIR"=>["GLIDER","ROCKING CHAIR","CHAIR FOR PREGNANT WOMEN"],
      "MASSAGE CHAIR"=>["POWERED CHAIR"],
      "MASSAGE RECLINER CHAIR"=>["POWERED CHAIR"],
      "OCCASIONAL CHAIR"=>["DINING CHAIR","CAPTAIN CHAIR","FORMAL CHAIR","CHAIR","DINNER CHAIR"],
      "ROCKER CHAIR"=>["ROCKING CHAIR","ROCKER"],
      "ROCKER"=>["RECLINER CHAIR","ROCKING CHAIR"],
      "SLEEPER CHAIR"=>["PULL OUT BED","HIDE A BED"],
      "WINGBACK CHAIR"=>["DINING CHAIR","CAPTAIN CHAIR","FORMAL CHAIR","CHAIR","LIVING ROOM CHAIR"],
      "ZERO GRAVITY CHAIR"=>["RECLINER CHAIR"],
      "ROCKER RECLINER CHAIR"=>["RECLINER CHAIR","ROCKER CHAIR"],
      "RECLINER CHAIR"=>["ROCKER","ZERO GRAVITY CHAIR","ROCKER CHAIR"],
      "SWIVEL ROCKER RECLINER CHAIR"=>["ROCKER CHAIR","RECLINER CHAIR","SWIVEL RECLINER CHAIR","SWIVEL CHAIR","SWIVEL ROCKER CHAIR"],
      "SWIVEL CHAIR"=>["SWIVEL ROCKER","SWIVEL RECLINER","SWIVEL ROCKER RECLINER CHAIR"],
      "SWIVEL ROCKER CHAIR"=>["SWIVEL CHAIR","SWIVEL ROCKER"],
      "SWIVEL RECLINER CHAIR"=>["SWIVEL RECLINER","SWIVEL CHAIR"],
      "CHAISE LOUNGE"=>["CHAIR","SOFA CHAIR","LIVING ROOM CHAIR","OVERSIZED CHAIR"],
      "SETTEE"=>["BENCH"],
      "BENCH"=>["SETTEE","PICNIC BENCH","FORMAL BENCH"],
      "RECLINER SOFA"=>["RECLINER COUCH"],
      "RECLINER LOVESEAT"=>["RECLINER COUCH","RECLINER SOFA"],
      "SLEEPER SOFA"=>["PULL OUT BED","PULL OUT MATTRESS","HIDE A BED"],
      "SLEEPER LOVESEAT"=>["PULL OUT BED","PULL OUT MATTRESS","HIDE A BED"], 
      "SECTIONAL"=>["ALL IN ONE COUCH","ALL IN ONE SOFA"],
      "SECTIONAL WITH SLEEPER"=>["ALL IN ONE COUCH","ALL IN ONE SOFA"],
      "SECTIONAL WITH RECLINER"=>["ALL IN ONE COUCH","ALL IN ONE SOFA"],
      "OTTAMAN"=>["FOOT STOOL"],
      "COFFEE TABLE"=>["COCKTAIL TABLE","LIVING ROOM TABLE","SOFA TABLE"],
      "END TABLE"=>["COUCH SIDE TABLE","LIVING ROOM TABLE"],
      "SOFA TABLE"=>["COUCH TABLE","LIVING ROOM TABLE"],
      "OCCASIONAL TABLE"=>["FORMAL TABLE","GUEST TABLE"],
      "TV STAND"=>["TELEVISION STAND","TV CONSOLE","ENTERTAINMENT CENTER"],
      "TV CONSOLE"=>["TELEVISION CONSOLE","TV STAND","ENTERTAINMENT CENTER","AUDIO CENTER","AUDIOVISUAL CENTER"],
      "ENTERTAINMENT CENTER"=>["TV STAND", "TV CONSOLE","AUDIO CENTER","AUDIOVISUAL CENTER"],
      "WALL UNIT"=>["DISPLAY UNIT","ENTERTAINMENT CENTER","BOOKCASE","BOOKSHELF"],
      "SHELF UNIT"=>["DISPLAY UNIT","BOOKCASE","ETAGERE","BOOKSHELF"],
      "STUDENT DESK"=>["WRITING DESK","LIGHT SCALED DESK","SMALL SCALED DESK"],
      "DESK"=>["RIGHT ANGLED DESK", "90 DEGREE DESK"],
      "WRITING DESK"=>["LIGHT SCALED DESK","SMALL SCALED DESK","STUDENT DESK"],
      "EXECUTIVE DESK"=>["LAWYER DESK","FORMAL DESK","MANAGEMENT DESK","OFFICE DESK"],
      "SECRETARY"=>["BOOKCASE WITH DESK","DESK WITH DISPLAY CASE","FOLD OUT DESK","DROP DOWN DESK","DROPDOWN DESK","FOLDOUT DESK"],
      "OFFICE CHAIR"=>["DESK CHAIR","TASK CHAIR","EXECUTIVE CHAIR","MANAGEMENT CHAIR"],
      "COMPUTER ARMOIRE"=>["COMPUTER CABINET"],
      "CREDENZA"=>["OFFICE WORKSPACE","OFFICE BOOKCASE","STORAGE CABINET","CABINET"],
      "BOOKCASE"=>["BOOKSHELF","SHELF UNIT","DISPLAY CABINET"],
      "PATIO TABLE"=>["OUTDOOR TABLE", "BALCONY TABLE", "GARDEN TABLE", "PICNIC TABLE"],
      "PICNIC TABLE"=>["OUTDOOR TABLE", "PARK TABLE", "GARGEN TABLE", "PATIO TABLE"],
      "PATIO CHAIR"=>["OUTDOOR CHAIR", "BALCONY CHAIR", "GARDEN CHAIR","LAWN CHAIR"],
      "PATIO BAR STOOL"=>["OUTDOOR BAR STOOL", "LAWN BAR STOOL", "BALCONY BAR STOOL", "GARDEN BAR STOOL", "BAR STOOL"],
      "LAWN CHAIR"=>["OUTDOOR CHAIR","GARDEN CHAIR","BALCONY CHAIR","LOUNGE CHAIR","POOLSIDE CHAIR","PATIO CHAIR"],
      "PATIO OTTOMAN"=>["OTTOMAN"],
      "PATIO BENCH"=>["OUTDOOR BENCH","GARDEN BENCH","PARK BENCH", "PICNIC BENCH"],
      "PICNIC BENCH"=>["OUTDOOR BENCH","GARDEN BENCH","PARK BENCH", "PATIO BENCH"],
      "PORCH SWING"=>["OUTDOOR SWING","PATIO SWING","GARDEN SWING","BENCH SWING"],
      "HAMMOCK"=>["SWING","SLING BED"],
      "PATIO COFFEE TABLE"=>["COFFEE TABLE"],
      "PATIO END TABLE"=>["END TABLE"],
      "DECK BOX"=>["OUTDOOR TRUNK","POOLSIDE BOX","POOLSIDE TRUNK"],
      "GAZEBO"=>["ALCOVE","BELVEDERE","PAVILION","SUMMERHOUSE","KIOSK"],
      "PATIO CART"=>["OUTDOOR CART","POOLSIDE CART"]
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
      "BENCH" => ["PICNIC TABLE", "BENCHES"],
      "CHINA HUTCH" => ["TACKBOARD"],
      "BUFFET"=>["GUN"],
      "DINING TABLE"=>["KIDS","COVER","CHAIRS","CHAIR"]
    }
  end
  
  def has_badword
    Table.badwords.each{|word| return true if self.keywords.include?(word)}
    (Table.badwords_by_item_type[self.item_type] || []).each{|word| return true if self.keywords.include?(word) }
    return false
  end
  
  def self.used_brand_name_hash
      {
        "AMERICAN DREW"=>0.0,
        "BAKER"=>0.0,
        "BALLARD DESIGNS"=>0.0,
        "BASSETT"=>0.0,
        "BERNHARDT"=>0.0,
        "BORKHOLDER"=>0.0,
        "BROYHILL"=> 0.0,
        "CALLIGARIS"=> 0.0,
        "CENTURY"=>0.0,
        "CHARLESTON FORGE"=>0.0,
        "COASTER"=>0.0,
        "CRATE & BARREL"=>0.0,
        "DANIA"=> 0.0,
        "DINEC"=>0.0,
        "DREXEL"=>0.0,
        "DREXEL HERITAGE"=>0.0,
        "DURHAM"=>0.0,
        "EKORNES"=>0.0,
        "ETHAN ALLEN"=>0.0,
        "FAIRFIELD CHAIR"=>0.0,
        "FAIRFIELD"=>0.0,
        "FLEXSTEEL"=>0.0,
        "GRANGE"=>0.0,
        "GUY CHADDOCK"=>0.0,
        "HABERSHAM"=>0.0,
        "HANCOCK & MOORE"=>0.0,
        "HARDEN"=>0.0,
        "HEKMAN"=>0.0,
        "HENKEL HARRIS"=>0.0,
        "HENREDON"=>0.0,
        "HERITAGE"=>0.0,
        "HICKORY"=>0.0,
        "HICKORY CHAIR"=>0.0,
        "HICKORY WHITE"=>0.0,
        "HOOKER"=>0.0,
        "IKEA"=>0.0,
        "JASPER"=>0.0,
        "JOINERY"=>0.0,
        "KINCAID"=>0.0,
        "KITCHEN KABOODLE"=>0.0,
        "KNOB CREEK"=>0.0,
        "KOHLS"=>0.0,
        "LA BARGE"=>0.0,
        "LANE"=>0.0,
        "LA Z BOY"=>0.0,
        "LEXINGTON"=>0.0,
        "LILLIAN AUGUST"=>0.0,
        "MAITLAND SMITH"=>0.0,
        "MARGE CARSON"=> 0.0,
        "MCGUIRE"=>0.0,
        "MITCHELL GOLD"=>0.0,
        "NATUZZI"=>0.0,
        "NICHOLS & STONE"=>0.0,
        "NORWALK"=>0.0,
        "PENNSYLVANIA HOUSE"=>0.0,
        "PIER 1"=>0.0,
        "POTTERY BARN"=>0.0,
        "PULASKI"=>0.0,
        "RESTORATION HARDWARE"=>0.0,
        "ROCHE BOBOIS"=>0.0,
        "ROMWEBER"=>0.0,
        "ROWE"=>0.0,
        "SALOOM"=>0.0,
        "SCHNADIG"=>0.0,
        "SHERRILL"=>0.0,
        "SITCOM"=>0.0,
        "SKOVBY"=>0.0,
        "STANLEY"=>0.0,
        "STICKLEY"=>0.0,
        "SWAIM"=>0.0,
        "TARGET"=>0.0,
        "THOMASVILLE"=>0.0,
        "TRICA"=>0.0,
        "VANGUARD"=>0.0,
        "WAL-MART"=>0.0,
        "WEST ELM"=>0.0,
        "WILLIAMS SONOMA"=>0.0,
        "WOODBRIDGE"=>0.0
      }
  end
  
  def self.used_item_type_hash
    {
      "DINING TABLE"=>0.0,
      "DINING CHAIR"=>0.0,
      "PUB TABLE"=>0.0,
      "BISTRO TABLE"=>0.0,
      "BAR STOOL"=>0.0,
      "CHINA HUTCH"=>-0.2,
      "CHINA CLOSET"=>-0.2,
      "BUFFET"=>-0.15,
      "SIDEBOARD"=>-0.1,
      "SERVER"=>-0.15,
      "BAR"=>-0.1,
      "BAR TABLE"=>-0.1,
      "DISPLAY CASE"=>-0.15,
      "CURIO"=>-0.15,
      "ETAGERE"=>-0.1,
      "CONSOLE"=>-0.1,
      "PLATFORM BED"=>0.0,
      "CAPTAIN BED"=>-0.10,
      "PIER BED"=>-0.15,
      "4 POSTER BED"=>-0.1,
      "CANOPY BED"=>-0.1,
      "TRUNDLE BED"=>-0.1,
      "DAY BED"=>-0.1,
      "FUTON"=>0.0,
      "DRESSER"=>0.0,
      "CHEST"=>0.0,
      "CHEST ON CHEST"=>-0.15,
      "GENTLEMAN CHEST"=>-0.15,
      "LINGERIE CHEST"=>0.0,
      "HIGH BOY"=>-0.2,
      "NIGHTSTAND"=>0.0,
      "ARMOIRE"=>-0.2,
      "VANITY TABLE"=>-0.1,
      "SOFA"=>0.0,
      "LOVESEAT"=>0.0,
      "CLUB CHAIR"=>0.0,
      "CHAIR"=>0.0,
      "DESK CHAIR"=>0.0,
      "HALF CHAIR"=>-0.1,
      "GLIDER CHAIR"=>0.0,
      "MASSAGE CHAIR"=>0.05,
      "MASSAGE RECLINER CHAIR"=>0.05,
      "OCCASIONAL CHAIR"=>-0.15,
      "RECLINER CHAIR"=>0.0,
      "ROCKER CHAIR"=>-0.15,
      "ROCKER RECLINER CHAIR"=>0.0,
      "SLEEPER CHAIR"=>-0.1,
      "SWIVEL CHAIR"=>0.0,
      "SWIVEL RECLINER CHAIR"=>0.0,
      "SWIVEL ROCKER CHAIR"=>0.0,
      "SWIVEL ROCKER RECLINER CHAIR"=>0.0,
      "WINGBACK CHAIR"=>-0.1,
      "ZERO GRAVITY CHAIR"=>0.0,
      "CHAISE LOUNGE"=>-0.15,
      "SETTEE"=>-0.15,
      "BENCH"=>-0.1,
      "RECLINER SOFA"=>0.0,
      "RECLINER LOVESEAT"=>0.0,
      "SLEEPER SOFA"=>0.0,
      "SLEEPER LOVESEAT"=>0.0,
      "SECTIONAL"=>0.0,
      "SECTIONAL WITH SLEEPER"=>0.0,
      "SECTIONAL WITH RECLINER"=>0.0,
      "OTTOMAN"=>0.0,
      "COFFEE TABLE"=>0.0,
      "END TABLE"=>0.0,
      "SOFA TABLE"=>-0.1,
      "OCCASIONAL TABLE"=>-0.15,
      "TV STAND"=>0.0,
      "TV CONSOLE"=>-0.1,
      "ENTERTAINMENT CENTER"=>-0.2,
      "WALL UNIT"=>-0.2,
      "SHELF UNIT"=>0.0,
      "DESK"=>-0.1,
      "STUDENT DESK"=>-0.1,
      "COMPUTER DESK"=>-0.2,
      "WRITING DESK"=>0.0,
      "EXECUTIVE DESK"=>-0.2,
      "SECRETARY"=>-0.2,
      "OFFICE CHAIR"=>0.0,
      "CABINET"=>0.0,
      "COMPUTER ARMOIRE"=>-0.2,
      "CREDENZA"=>-0.1,
      "BOOKCASE"=>0.0
    }
  end
  
  def self.used_patio_item_type_hash 
    {
      "PATIO TABLE"=>-0.00,
      "PICNIC TABLE"=>-0.05,
      "PATIO CHAIR"=>-0.00,
      "PATIO BAR STOOL"=>-0.00,
      "LAWN CHAIR"=>-0.00,
      "PATIO OTTOMAN"=>-0.00,
      "PATIO BENCH"=>-0.00,
      "PICNIC BENCH"=>-0.05,
      "PORCH SWING"=>-0.00,
      "HAMMOCK"=>-0.05,
      "PATIO COFFEE TABLE"=>-0.00,
      "PATIO END TABLE"=>-0.00,
      "DECK BOX"=>-0.05,
      "GAZEBO"=>-0.05,
      "PATIO CART"=>-0.05
    }
  end
  
  def self.used_material_hash
    {
      "PARTICLE BOARD": -0.1,
      "PLYWOOD": -0.05,
      "PLASTIC": -0.05,
      "CEDAR": -0.05,
      "FAUX MARBLE": -0.05,
      "FAUX STONE": -0.05,
      "GLASS": -0.05,
      "LARGE GLASS TOP DINING TABLES": -0.1,
      "MAPLE": -0.05,
      "PINE": -0.05,
      "METAL": -0.05,
      "IRON": -0.05,
      "OAK": -0.05,
      "MISSION OAK": -0.05,
      "QUARTER SAWN OAK": 0.05,
      "ASH": -0.05,
      "BURL": 0.05,
      "BAMBOO": 0.05,
      "CHERRY": 0.05,
      "MAHOGANY": 0.05,
      "MARBLE": 0.05,
      "ROSEWOOD": 0.05,
      "STONE": 0.05,
      "TEAK": 0.0,
      "WALNUT": 0.05,
      "RATTAN": -0.0,
      "WICKER": -0.05,
      "CONCRETE": -0.1,
      "SLATE": -0.05,
      "NONE": 0.0
    }
  end
  
  def self.used_patio_material_hash 
    {
      "PLASTIC"=>-0.05,
      "FAUX MARBLE"=>-0.05,
      "FAUX STONE"=>-0.05,
      "GLASS"=>-0.00,
      "PLYWOOD"=>-0.05,
      "MAPLE"=>-0.05,
      "PINE"=>-0.05,
      "OAK"=>-0.05,
      "CEDAR"=>-0.05,
      "MISSION OAK"=>-0.05,
      "QUARTER SAWN OAK"=>0.05,
      "ASH"=>-0.05,
      "BURL"=>0.05,
      "EBONY"=>0.05,
      "CHERRY"=>0.05,
      "MAHOGANY"=>0.05,
      "ROSEWOOD"=>0.05,
      "TEAK"=>-0.00,
      "WALNUT"=>0.05,
      "SCROLLED IRON"=>-0.00,
      "BAMBOO"=>0.05,
      "MARBLE"=>0.05,
      "STONE"=>0.05,
      "RATTAN"=>0.05,
      "WICKER"=>-0.05,
      "CONCRETE"=>-0.10,
      "SLATE"=>-0.05,
      "ROPE"=>-0.00,
      "UPHOLSTERY"=>-0.00
    }
  end
  
  def self.used_patio_material_of_base_hash
    {
      "PLYWOOD"=>-0.00,
      "SOLID WOOD"=>0.05,
      "SCROLLED IRON"=>-0.00,
      "PLASTIC"=>-0.05,
      "STONE"=>0.05,
      "FAUX STONE"=>-0.00,
      "FAUX MARBLE"=>-0.00,
      "CONCRETE"=>-0.10,
      "RATTAN"=>0.05,
      "BAMBOO"=>0.05,
      "WICKER"=>-0.05
    }
  end
  
  def self.used_patio_fabric_pattern_hash
    { 
      "SOLID"=>-0.00,
      "STRIPE"=>-0.00,
      "CHECKERED"=>-0.00,
      "ZIG ZAG"=>-0.00,
      "FLORAL"=>-0.05,
      "CIRCLES"=>-0.00,
      "PLAID"=>-0.05,
      "ABSTRACT"=>-0.05,
      "PRINT"=>-0.05,
      "DIAMOND"=>-0.05,
      "TAPESTRY"=>-0.05,
      "ALLIGATOR"=>-0.05,
      "LEOPARD"=>-0.05,
      "TIGER"=>-0.05,
      "POLKA DOT"=>-0.00,
      "NO FABRIC"=>-0.00
    }
  end
  
  def self.used_patio_fabric_color_hash
    {
      "ALL BROWNS"=>-0.00,
      "ALL TANS"=>-0.00,
      "ALL BEIGES"=>-0.00,
      "ALL BLACKS"=>-0.05,
      "ALL GRAYS"=>-0.05,
      "GOLD"=>-0.05,
      "SILVER"=>-0.05,
      "WHITE"=>-0.05,
      "CREAM"=>-0.05,
      "BRIGHT"=>-0.05,
      "PASTEL"=>-0.00,
      "FADED"=>-0.00,
      "DARK"=>-0.00,
      "BABY"=>-0.05,
      "NO FABRIC"=>-0.00
    }
  end
  
  def self.used_patio_seat_or_cushion_hash
    {
      "YES": 0.05,
      "NO": -0.05
    }
  end
  
  def self.used_carved_detailing_hash
    {
      "YES": 0.05,
      "NO": 0.0
    }
  end
  
  def self.used_nailhead_trimming_hash 
    {
      "YES": 0.05,
      "NO": 0.0
    }
  end  
  
  def self.used_material_of_base_hash
    {
      "PLYWOOD": 0.0,
      "WOOD": 0.0,
      "SOLID WOOD": 0.05,
      "SCROLLED IRON": -0.05,
      "IRON": -0.05,
      "CHROME": -0.05,
      "PLASTIC": -0.05,
      "STONE": 0.05,
      "FAUX STONE": 0.0,
      "FAUX MARBLE": 0.0,
      "CONCRETE": -0.1,
      "GLASS": 0.0,
      "BAMBOO": 0.05,
      "RATTAN": 0.0,
      "WICKER": -0.05,
      "NONE": 0.0
    }
  end
  
  def self.used_material_of_shelves_hash
    {
      "PLYWOOD": 0.0,
      "PARTICLE BOARD": -0.05,
      "MARBLE": 0.05,
      "STONE": 0.05,
      "FAUX MARBLE": 0.0,
      "FAUX STONE": 0.0,
      "GLASS": 0.0,
      "PLASTIC": -0.05,
      "METAL": -0.05,
      "SLATE": -0.05,
      "NONE": 0.0
    }
  end
  
  def self.used_finish_type_hash
    {
      "DISTRESSED": 0.0,
      "RUSTIC": -0.05,
      "WHITE WASHED": -0.05,
      "MIRRORED": -0.1,
      "LIGHT": -0.05,
      "MEDIUM": 0.0,
      "DARK": 0.05,
      "PHOTO FINISH": -0.1,
      "WOOD": 0.05,
      "VENEER ON SOLID WOOD": 0.05,
      "VENEER ON PLYWOOD": 0.0,
      "VENEER ON PARTICLE BOARD": -0.05,
      "NONE": 0.0
    }
  end
  
  def self.used_backrest_style_hash
    {
      "SOLID": 0.0,
      "SLATTED": 0.0,
      "LADDER": 0.0,
      "SHIELD": 0.05,
      "WINDSOR": -0.05,
      "QUEEN ANNE": 0.05,
      "EMPIRE": 0.05,
      "CHIPPENDALE": 0.05,
      "NAPOLEON": 0.05,
      "LATTICE": 0.0,
      "X": 0.0,
      "ABSTRACT": 0.0,
      "OVAL": 0.0,
      "HARP": -0.05,
      "UPHOLSTERED": 0.0,
      "NONE": 0.0
    }
  end
  
  def self.used_fabric_type_hash
    {
      "MICROFIBER": -0.05,
      "CHENILLE": 0.0,
      "POLYESTER": -0.05,
      "HEAVY COTTON TWILL": -0.05,
      "VELVET": 0.05,
      "SUEDE": 0.0,
      "SILK": 0.05,
      "BURLAP": -0.05,
      "CANVAS": -0.05,
      "LEATHER": 0.0,
      "FUR": 0.0,
      "VINYL": -0.05,
      "DAMASK": 0.05,
      "CANE": 0.0,
      "RUSH": -0.05,
      "MESH": -0.05,
      "NONE": 0.0
    }
  end
  
  def self.used_fabric_pattern_hash
    { 
      "SOLID": 0.0,
      "STRIPE": 0.0,
      "CHECKERED": -0.05,
      "ZIG ZAG": -0.05,
      "FLORAL": -0.1,
      "CIRCLES": -0.05,
      "PLAID": -0.05,
      "ABSTRACT": -0.05,
      "PRINT": -0.05,
      "DIAMOND": -0.05,
      "TAPESTRY": -0.05,
      "ALLIGATOR": -0.05,
      "LEOPARD": -0.05,
      "TIGER": -0.05,
      "POLKA DOT": -0.05,
      "NONE": 0.0
    }
  end
  
  def self.used_fabric_color_hash
    {
      "ALL BROWNS": 0.05,
      "ALL TANS": 0.05,
      "ALL BLACKS": 0.05,
      "ALL BEIGES": 0.05,
      "ALL GREYS": 0.05,
      "CREAM": 0.0,
      "WHITE": 0.0,
      "GOLD": 0.0,
      "SILVER": 0.0,
      "BRIGHT": -0.1,
      "PASTEL": -0.05,
      "FADED": -0.05,
      "DARK": 0.05,
      "BABY": -0.1,
      "NONE": 0.0
    }
  end
  
  #CARVED? increase price by ten
  
  def self.used_furniture_style_hash
    {
      "ARTS & CRAFTS": -0.1,
      "ASIAN": -0.05,
      "CLASSIC CONTEMPORARY": -0.05,
      "CONTEMPORARY": 0.05,
      "COUNTRY": -0.1,
      "INDUSTRIAL": -0.1,
      "MODERN": 0.05,
      "NEOCLASSICAL": -0.05,
      "RUSTIC": -0.1,
      "SHABBY CHIC": -0.05,
      "TRADITIONAL": -0.05,
      "TUSCAN": -0.05,
      "NONE": 0.0
    }
  end
  
  def self.used_material_of_insets_hash
    {
      "GLASS": 0.0,
      "STONE": 0.0,
      "MARBLE": 0.0,
      "LEATHER": 0.0,
      "FAUX STONE": -0.05,
      "FAUX MARBLE": -0.05,
      "SLATE": -0.05,
      "NONE": 0.0
    }
  end
  
  def self.all_options(is_patio = false)
    if is_patio
      {
        "item_type": Table.used_patio_item_type_hash,
        "brand_name": Table.used_brand_name_hash,
        "fabric_color": Table.used_patio_fabric_color_hash,
        "fabric_pattern": Table.used_patio_fabric_pattern_hash,
        "fabric_type": Table.used_fabric_type_hash,
        "finish_type": Table.used_finish_type_hash,
        "material_of_base": Table.used_patio_material_of_base_hash,
        "material_of_insets": Table.used_material_of_insets_hash,
        "material": Table.used_patio_material_hash,  
        "seat_or_cushion": Table.used_patio_seat_or_cushion_hash
      }
    else
      { 
        "item_type": Table.used_item_type_hash,
        "brand_name": Table.used_brand_name_hash,
        "furniture_style": Table.used_furniture_style_hash,
        "fabric_color": Table.used_fabric_color_hash,
        "fabric_pattern": Table.used_fabric_pattern_hash,
        "fabric_type": Table.used_fabric_type_hash,
        "backrest_style": Table.used_backrest_style_hash,
        "finish_type": Table.used_finish_type_hash,
        "material_of_shelves": Table.used_material_of_shelves_hash,
        "material_of_base": Table.used_material_of_base_hash,
        "material_of_insets": Table.used_material_of_insets_hash,
        "material": Table.used_material_hash,  
        "carved_detailing": Table.used_carved_detailing_hash,
        "nailhead_trimming": Table.used_nailhead_trimming_hash
      }
    end
  end
  
  def self.all_materials
    (patio_materials+materials).uniq.sort
  end
  
  def self.patio_materials
    Table.used_patio_material_hash.keys.sort
  end
  
  def self.materials
    Table.used_material_hash.keys.sort
  end
  
  def self.all_item_types
    (item_types + patio_item_types).sort
  end
  
  def self.item_types
    Table.used_item_type_hash.keys.sort
  end
  
  def self.patio_item_types
    Table.used_patio_item_type_hash.keys.sort
  end
  
  def self.all_non_standard_item_types
    (Table.all_item_types+Table.standardized_item_types.keys()).uniq.sort
  end

  def self.all_brand_names
    Table.used_brand_name_hash.keys.sort
  end
  
  private
  def capitalize_attributes
    write_attribute(:name,self.name.upcase.gsub(/[^0-9A-Z ]/i,'').strip) if self.name != self.name.upcase.gsub(/[^0-9A-Z ]/i,'').strip
    write_attribute(:item_type,self.item_type.upcase.gsub(/[^0-9A-Z ]/i,'').strip) if self.item_type.present? and self.item_type != self.item_type.upcase.gsub(/[^0-9A-Z ]/i,'').strip
    write_attribute(:brand_name,self.brand_name.upcase.gsub(/[^0-9A-Z ]/i,'').strip) if self.brand_name.present? and self.brand_name != self.brand_name.upcase.gsub(/[^0-9A-Z ]/i,'').strip
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
    #validate duplicates
    duplicate_table_ids = Table.where(
      price: self.price,
      brand_name: self.brand_name,
      item_type: ([self.item_type]+(Table.similar_item_type_hash[self.item_type] || []))
    ).pluck(:id)
    errors.add(:duplicate_record_found, "Duplicate record found") if (duplicate_table_ids-[self.id]).present?
    #is part of a set or a toy
    errors.add(:bad_keywords, "Found bad keywords") if self.has_badword
    
  end
  
end

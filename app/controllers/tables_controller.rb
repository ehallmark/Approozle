class TablesController < ApplicationController
  require 'semantics3'

  # Your Semantics3 API Credentials
  API_KEY = 'SEM3259890376C6C204B176FF18706FB87EB'
  API_SECRET = 'Y2JmZjY1NjU5NDM2YjljMmU3ZmQ4YjBhZjRjMGUwNTg'
  
  def create
    @table = Table.new
  end

  def new
    if Table.create(table_params)
      # success
      redirect_to tables_path, :notice=>"Successfully created"
    else
      # error handling
      redirect_to :back, :alert=>"Unable to create"
    end
  end
  
  def get_products
    # Set up a client to talk to the Semantics3 API
    sem3 = Semantics3::Products.new(API_KEY,API_SECRET)
    # Build the request
    product_type = params[:product_type]
    sem3.products_field( "name", product_type )
    sem3.products_field( "fields", ["name", "features", "manufacturer", "seller", "brand", "material", "price"] )
    
    # Run the request
    begin 
      @productsHash = sem3.get_products()
    rescue
      @productsHash = {}
    end
    
 
    page = 0 
    while (@productsHash.present?) do
      page = page + 1 
      puts "We are at page = #{page}"
      break if not @productsHash.try(:[],"results").present?
      @productsHash["results"].each do |p|
        p.each_key{|k| k = k.downcase if not p.include?(k.downcase) }
        puts p.inspect
        brand = p.try(:[],"brand")
        brand = p.try(:[],"seller") if not brand.present?
        brand = p.try(:[],"manufacturer") if not brand.present?
        price = p.try(:[],"price")
        name = p.try(:[],"name")
        material = p.try(:[],"material")
        features = p.try(:[],"features")
        if features.present? and not material.present?
          features.each_key{|k| 
            k = k.downcase
            k = 'material' if k.include?('material') and not features.include?('material')
          }
          material = features.try(:[],"material")
        end
        puts price
        puts brand
        puts material
        if price.present? and brand.present?
          pHash = {
            price: price,
            brand_name: brand,
            material: material,
            item_type: product_type,
            name: name
          }
          Table.find_or_create_by(pHash)
        end
      end
       
      # Goto the next 'page'
      @productsHash = sem3.iterate_products
    end
    
    redirect_to tables_path
  end
  
  def delete
    if (params[:id] and Table.destroy(params[:id])) 
      redirect_to :back, :notice => "Successfully deleted"
    else
      redirect_to :back, :alert => "Unable to delete"
    end
  end
  
  def update
    @table = Table.find(params[:id])
    if @table.update_attributes(table_params)
      redirect_to :back, notice => "Successfully updated"
    else
      redirect_to :back, alert => "Unable to update"
    end
  end
  
  def edit
    @table = Table.find(params[:id])
  end

  def show
    @table = Table.find(params[:id])
  end

  def index
    @tables = Table.order("brand_name ASC NULLS LAST")
  end

  private
    # Using a private method to encapsulate the permissible parameters is just a good pattern
    # since you'll be able to reuse the same permit list between create and update. Also, you
    # can specialize this method with per-user checking of permissible attributes.
    def table_params
      params.require(:table).permit!
    end

end

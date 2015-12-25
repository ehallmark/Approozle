class TablesController < ApplicationController
  require 'semantics3'

  # Your Semantics3 API Credentials
  API_KEY = 'SEM3259890376C6C204B176FF18706FB87EB'
  API_SECRET = 'Y2JmZjY1NjU5NDM2YjljMmU3ZmQ4YjBhZjRjMGUwNTg'
  
  def create
    @table = Table.new
  end

  def new
    if table = Table.create(table_params)
      # success
      redirect_to tables_path, :notice=>"Successfully created"
    else
      # error handling
      puts table.errors.messages.inspect
      redirect_to :back, :alert=>"Unable to create"
    end
  end
  
  def get_products    
    raise unless params[:product_type].present?
    # Set up a client to talk to the Semantics3 API
    sem3 = Semantics3::Products.new(API_KEY,API_SECRET)
    # Build the request
    product_type = params[:product_type]
    # we only want single items so skip anything with 'SET' in it
    sem3.products_field( "name", "include" , product_type )
    sem3.products_field( "name", "exclude" , ["set","toy","miniature","mini"] ) 
    sem3.products_field( "price", "gt", 20 )
    product_type = product_type.upcase
    begin
      offset = Float(params[:offset])
      offset = offset.to_i
    rescue
      offset = nil
    end
    sem3.products_field( "offset", offset ) if offset.present?
    # Run the request
    begin 
      @productsHash = sem3.get_products()
    rescue
      @productsHash = {}
    end
    
 
    page = 0 
    new_record_count = 0
    while (@productsHash.present?) do
      page = page + 1 
      puts "We are at page = #{page}"
      puts @productsHash.inspect
      break if not @productsHash.try(:[],"results").present?
      @productsHash["results"].each do |p|
        name = p.try(:[],"name")
        material = []
        p.each{|k,v| 
          material.push(v.upcase) if k.downcase.include?('material') and v.present?
        }
        puts p.inspect
        brand = p.try(:[],"brand")
        brand = p.try(:[],"seller") if not brand.present?
        brand = p.try(:[],"manufacturer") if not brand.present?
        price = p.try(:[],"price")
        features = p["features"] if p.has_key?("features")
        if features.present? and not material.present?
          features.each{|k,v| 
            material.push(v.upcase) if k.downcase.include?('material') and v.present?
          }
        end
        material = material.uniq.join('; ')
        puts price
        puts brand
        puts material
        brand = brand.upcase if brand.present?
        name = name.upcase if name.present?
        material = material.upcase if name.present?
        if price.present? and brand.present? and name.present?
          pHash = {
            price: price,
            brand_name: brand,
            item_type: product_type,
            name: name
          }
          # looks to update material in case I come up with a better algorithm in the future
          
          identical_tables = Table.where(pHash.merge(material: material))
          new_record_count -= identical_tables.count
          identical_tables.destroy_all
          less_interesting_tables = Table.where(pHash.merge(material: nil))
          new_record_count -= less_interesting_tables.count
          less_interesting_tables.destroy_all
          # Destroy common materials
          common_tables = Table.where(pHash)
          if common_tables.exists?
            common_tables.each do |t|
              if material.include?(t.material)
                t.destroy
                new_record_count -= 1
              end
            end
          end
          if table = Table.create(pHash.merge(material: material))     
            new_record_count += 1
          else
             puts table.errors.messages.inspect
          end
        end
      end
       
      # Goto the next 'page'
      begin
        @productsHash = sem3.iterate_products
      rescue
        break
      end
    end
    puts "New records created: #{new_record_count}"
    redirect_to tables_path
  end
  
  def update_tables_item_type_index
    Table.joins("join tables as tables_2 on (tables.item_type = tables_2.item_type)").where('tables_2.price is not NULL and tables.item_type is not NULL').select("tables.*, avg(tables_2.price) as avg_price").group("tables.id").each{|t|
      t.update_attributes(item_type_index: t.avg_price)
    }
    redirect_to :back, notice: "Update complete!"
  end
  
  def update_tables_brand_name_index
    Table.joins("join tables as tables_2 on (tables.brand_name = tables_2.brand_name)").where('tables_2.price is not NULL and tables.brand_name is not NULL').select("tables.*, avg(tables_2.price) as avg_price").group("tables.id").each{|t|
      t.update_attributes(brand_name_index: t.avg_price)
    }
    redirect_to :back, notice: "Update complete!"
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
      puts @table.errors.messages.inspect
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
    #Table.where(price: nil).destroy_all
    all_tables = Table.order("item_type ASC NULLS LAST, brand_name ASC NULLS LAST, price DESC NULLS LAST")
    @filterrific = initialize_filterrific(
      all_tables,
      params[:filterrific]
    ) or return
    @tables = @filterrific.find.page(params[:page])

    respond_to do |format|
      format.html
      format.js
    end
  end
  
  def seed
    
  end
  
  def analysis
    @item_type_price_averages = Table.joins("join tables as tables_2 on (tables.item_type = tables_2.item_type)").where("tables.item_type is not NULL").select("tables.item_type, tables.item_type_index, count(tables_2.id) as total_count").order("total_count desc").group("tables.id").uniq.compact
    @brand_price_averages = Table.joins("join tables as tables_2 on (tables.brand_name = tables_2.brand_name)").where("tables.brand_name is not NULL").select("tables.brand_name, tables.brand_name_index, count(tables_2.id) as total_count").order("total_count desc").group("tables.id").uniq.compact
    @total_count = Table.all.length
  end

  private
    # Using a private method to encapsulate the permissible parameters is just a good pattern
    # since you'll be able to reuse the same permit list between create and update. Also, you
    # can specialize this method with per-user checking of permissible attributes.
    def table_params
      params.require(:table).permit!
    end

end

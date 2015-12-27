class TablesController < ApplicationController
  require 'semantics3'

  # Your Semantics3 API Credentials
  API_KEY = 'SEM3259890376C6C204B176FF18706FB87EB'
  API_SECRET = 'Y2JmZjY1NjU5NDM2YjljMmU3ZmQ4YjBhZjRjMGUwNTg'
  
  def appraisal_index
  end
  
  def appraisal_results
    table = params[:table]
    if table.present?
      table.has_key?(:brand_name) ? @brand_name = table[:brand_name].upcase : @brand_name = ""
      table.has_key?(:item_type) ? @item_type = table[:item_type].upcase : @item_type = ""
      table.has_key?(:material) ? @material = table[:material].upcase : @material = ""
      table.has_key?(:name) ? @name = table[:name].upcase : @name = ""
      
      @from_brand_names = Table.where("brand_name ilike '%#{@brand_name}%' or name ilike '%#{@brand_name}%'") if @brand_name.present?
      begin @brand_name_index = @from_brand_names.pluck(:brand_name_index).sum/@from_brand_names.count rescue @brand_name_index = "N/A" end
      @from_item_types = Table.where("item_type = '#{@item_type}' or name ilike '%#{@item_type}%'") if @item_type.present?
      begin @item_type_index = @from_item_types.pluck(:item_type_index).sum/@from_item_types.count rescue @item_type_index = "N/A" end
      @from_materials = Table.where("material ilike '%#{@material}%' or name ilike '%#{@material}%'") if @material.present?
      @from_names = Table.search_query(@name) if @name.present?
      @brand_name_count = (@from_brand_names || []).count
      @item_type_count = (@from_item_types || []).count
      @material_count = (@from_materials || []).count
      @name_count = (@from_names || []).count
      @total_count = @brand_name_count+@item_type_count+@material_count+@name_count
      begin @brand_name_price_average = @from_brand_names.pluck(:price).sum/@brand_name_count rescue @brand_name_price_average = "N/A" end
      begin @item_type_price_average = @from_item_types.pluck(:price).sum/@item_type_count rescue @item_type_price_average = "N/A" end
      begin @material_price_average = @from_materials.pluck(:price).sum/@material_count rescue @material_price_average = "N/A" end
      begin @name_price_average = @from_names.pluck(:price).sum/@name_count rescue @name_price_average = "N/A" end
      attributes_prices = [@brand_name_price_average,@item_type_price_average,@material_price_average,@name_price_average].keep_if{|item|
        item.present? and item != "N/A"
      }
      begin @weighted_brand_name_average = @brand_name_price_average.to_f*@brand_name_count/@total_count rescue @weighted_brand_name_average = "N/A" end
      begin @weighted_item_type_average = @item_type_price_average.to_f*@item_type_count/@total_count rescue @weighted_item_type_average = "N/A" end
      begin @weighted_material_average = @material_price_average.to_f*@material_count/@total_count rescue @weighted_material_average = "N/A" end
      begin @weighted_name_average = @name_price_average.to_f*@name_count/@total_count rescue @weighted_name_average = "N/A" end
      attributes_prices = [@brand_name_price_average,@item_type_price_average,@material_price_average,@name_price_average].keep_if{|item|
        item.present? and item != "N/A"
      }
      begin @total_price_average = attributes_prices.sum/attributes_prices.length rescue @total_price_average = "N/A" end      
      weighted_attributes_prices = [@weighted_brand_name_average,@weighted_item_type_average,@weighted_material_average,@weighted_name_average].keep_if{|item|
        item.present? and item != "N/A"
      }
      begin @total_weighted_price_average = weighted_attributes_prices.sum rescue @total_weighted_price_average = "N/A" end
    end
    
  end
  
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
    sem3.products_field( "name", "exclude" , "set toy miniature" ) 
    sem3.products_field( "brand", params[:brand_name]) if params[:brand_name].present?
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
      unless t.update_attributes(item_type_index: t.avg_price)
        puts t.errors.messages.inspect
      end
    }
    redirect_to :back, notice: "Update complete!"
  end
  
  def update_tables_brand_name_index
    Table.joins("join tables as tables_2 on (tables.brand_name = tables_2.brand_name)").where('tables_2.price is not NULL and tables.brand_name is not NULL').select("tables.*, avg(tables_2.price) as avg_price").group("tables.id").each{|t|
      unless t.update_attributes(brand_name_index: t.avg_price)
        puts t.errors.messages.inspect
      end
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

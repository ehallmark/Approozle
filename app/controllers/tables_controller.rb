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
      table.has_key?(:brand_name) ? @brand_name = table[:brand_name].upcase.gsub(/[^0-9A-Z ]/i,'') : @brand_name = ""
      table.has_key?(:item_type) ? @item_type = table[:item_type].upcase.gsub(/[^0-9A-Z ]/i,'') : @item_type = ""
      table.has_key?(:material) ? @material = table[:material].upcase.gsub(/[^0-9A-Z ]/i,'') : @material = ""
      table.has_key?(:name) ? @name = table[:name].upcase.gsub(/[^0-9A-Z ]/i,'') : @name = ""
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
      begin @brand_name_price_average = @from_brand_names.pluck(:price).sum/@brand_name_count rescue @brand_name_price_average = "N/A" end
      begin @item_type_price_average = @from_item_types.pluck(:price).sum/@item_type_count rescue @item_type_price_average = "N/A" end
      begin @material_price_average = @from_materials.pluck(:price).sum/@material_count rescue @material_price_average = "N/A" end
      begin @name_price_average = @from_names.pluck(:price).sum/@name_count rescue @name_price_average = "N/A" end
      # variables to standardize above variables
      begin @material_boost_from_item_type = @from_materials.pluck(:item_type_index).sum.to_f/@material_count.to_f rescue @material_boost_from_item_type = "N/A" end
      begin @brand_name_boost_from_item_type = @from_brand_names.pluck(:item_type_index).sum.to_f/@brand_name_count.to_f rescue @brand_name_boost_from_item_type = "N/A" end
      begin @name_boost_from_item_type = @from_names.pluck(:item_type_index).sum.to_f/@name_count.to_f rescue @name_boost_from_item_type = "N/A" end
      # readjust variables to account for weakness of material attribute completeness
      @brand_name_count = @item_type_count if @brand_name_count > @item_type_count
      @brand_name_count = @item_type_count/4 if @brand_name_count > 0 and @brand_name_count < @item_type_count/4
      @material_count = @item_type_count/3 if @material_count > 3*@item_type_count
      @material_count = @item_type_count/100 if @material_count > 0 and @material_count < @item_type_count / 100
      @name_count = @item_type_count if @name_count > @item_type_count
      @name_count = @item_type_count/10 if @name_count > 0 and @name_count < @item_type_count/10
      @total_count = @brand_name_count+@item_type_count+@material_count+@name_count
      # get weighted variables
      begin @item_type_adjusted_for_brand_name = @item_type_price_average*@brand_name_price_average/@brand_name_boost_from_item_type rescue @item_type_adjusted_for_brand_name = "N/A" end
      begin @item_type_adjusted_for_material = @item_type_price_average*@material_price_average/@material_boost_from_item_type rescue @item_type_adjusted_for_material = "N/A" end
      begin @item_type_adjusted_for_name = @item_type_price_average*@name_price_average/@name_boost_from_item_type rescue @item_type_adjusted_for_name = "N/A" end
      begin @item_type_weighted_by_brand_name = @item_type_adjusted_for_brand_name*@brand_name_count rescue @item_type_weighted_by_brand_name = "N/A" end
      begin @item_type_weighted_by_material = @item_type_adjusted_for_material*@material_count rescue @item_type_weighted_by_material = "N/A" end
      begin @item_type_weighted_by_name = @item_type_adjusted_for_name*@name_count rescue @item_type_weighted_by_name = "N/A" end
      begin @item_type_weighted = @item_type_price_average*@item_type_count rescue @item_type_weighted = "N/A" end
      # get final results
      weighted_item_type_adjustments = [@item_type_weighted_by_brand_name, @item_type_weighted_by_material, @item_type_weighted_by_name, @item_type_weighted].keep_if{|item|
        item.present? and item != "N/A"
      }
      begin @adjusted_and_weighted_item_type_average = weighted_item_type_adjustments.sum.to_f/@total_count rescue @adjusted_and_weighted_item_type_average = "N/A" end
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
    product_type = product_type.upcase.gsub(/[^0-9A-Z ]/i,'').strip
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
          material.push(v.upcase.gsub(/[^0-9A-Z ]/i,'')) if k.downcase.include?('material') and v.present?
        }
        puts p.inspect
        brand = p.try(:[],"brand")
        brand = p.try(:[],"seller") if not brand.present?
        brand = p.try(:[],"manufacturer") if not brand.present?
        price = p.try(:[],"price")
        features = p["features"] if p.has_key?("features")
        if features.present? and not material.present?
          features.each{|k,v| 
            material.push(v.upcase.gsub(/[^0-9A-Z ]/i,'')) if k.downcase.include?('material') and v.present?
          }
        end
        material = material.uniq.join(' ')
        puts price
        puts material
        brand = brand.upcase.gsub(/[^0-9A-Z ]/i,'') if brand.present?
        name = name.upcase.gsub(/[^0-9A-Z ]/i,'') if name.present?
        material = material.upcase.gsub(/[^0-9A-Z ]/i,'') if name.present?
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
  
  def update_tables_validations
    Table.all.each{|t|
      unless t.save
        puts t.errors.messages.inspect
        t.destroy
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

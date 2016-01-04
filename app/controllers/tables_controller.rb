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
      table.has_key?(:brand_name) ? @brand_name = table[:brand_name].upcase.gsub(/[^0-9A-Z ]/i,'').strip : @brand_name = ""
      table.has_key?(:item_type) ? @item_type = table[:item_type].upcase.gsub(/[^0-9A-Z ]/i,'').strip : @item_type = ""
      table.has_key?(:material) ? @material = table[:material].upcase.gsub(/[^0-9A-Z ]/i,'').strip : @material = ""
      table.has_key?(:optional_search) ? @name = table[:optional_search].upcase.gsub(/[^0-9A-Z ]/i,'').strip : @name = ""
      @from_brand_names = Table.where(([@brand_name]+(Table.similar_brand_name_hash[@brand_name] || [])).compact.collect{|brand_name| "brand_name ilike '%#{brand_name}%' or name ilike '%#{brand_name}%'"}.join(" or ")) if @brand_name.present?
      @from_item_types = Table.where(([@item_type]+(Table.similar_item_type_hash[@item_type] || [])).compact.collect{|item_type| "item_type = '#{item_type}' or name ilike '%#{item_type}%'"}.join(" or ")) if @item_type.present?
      @from_materials = Table.where(([@material]+(Table.similar_material_hash[@material] || [])).compact.collect{|material| "material ilike '%#{material}%' or name ilike '%#{material}%'"}.join(" or ")) if @material.present?
      @from_names = Table.where(:id => @name.split(" ").collect{|name| ([name]+(Table.similar_search_options_hash[name] || [])) }.inject(:+).compact.uniq.collect{|n| Table.search_query(n).map(&:id) }.inject(:+).uniq ) if @name.present?
      @brand_name_count = (@from_brand_names || []).count
      @item_type_count = (@from_item_types || []).count
      @material_count = (@from_materials || []).count
      @name_count = (@from_names || []).count
      # Average of mean AND median
      begin @brand_name_price_mean = @from_brand_names.pluck(:price).sum/@brand_name_count rescue @brand_name_price_mean = "N/A" end
      begin @brand_name_price_median = @from_brand_names.order(:price)[@brand_name_count/2].price rescue @brand_name_price_median = "N/A" end
      begin @brand_name_price_average = [@brand_name_price_median,@brand_name_price_median,@brand_name_price_mean].sum/3.0 rescue @brand_name_price_average = "N/A" end
      begin @item_type_price_mean = @from_item_types.pluck(:price).sum/@item_type_count rescue @item_type_price_mean = "N/A" end
      begin @item_type_price_median = @from_item_types.order(:price)[@item_type_count/2].price rescue @item_type_price_median = "N/A" end
      begin @item_type_price_average = [@item_type_price_median,@item_type_price_median,@item_type_price_mean].sum/3.0 rescue @item_type_price_average = "N/A" end
      begin @material_price_mean = @from_materials.pluck(:price).sum/@material_count rescue @material_price_mean = "N/A" end
      begin @material_price_median = @from_materials.order(:price)[@material_count/2].price rescue @material_price_median = "N/A" end
      begin @material_price_average = [@material_price_median,@material_price_median,@material_price_mean].sum/3.0 rescue @material_price_average = "N/A" end
      begin @name_price_mean = @from_names.pluck(:price).sum/@name_count rescue @name_price_mean = "N/A" end
      begin @name_price_median = @from_names.order(:price)[@name_count/2].price rescue @name_price_median = "N/A" end
      begin @name_price_average = [@name_price_median,@name_price_median,@name_price_mean].sum/3.0 rescue @name_price_average = "N/A" end
      # variables to standardize above variables
      begin 
        raise if @material_count == 0
        @material_boost_from_item_type = @from_materials.pluck(:item_type_index).sum.to_f/@material_count.to_f 
      rescue 
        @material_boost_from_item_type = "N/A" 
      end
      begin 
        raise if @brand_name_count == 0
        @brand_name_boost_from_item_type = @from_brand_names.pluck(:item_type_index).sum.to_f/@brand_name_count.to_f 
      rescue
        @brand_name_boost_from_item_type = "N/A"
      end
      begin
        raise if @name_count == 0
        @name_boost_from_item_type = @from_names.pluck(:item_type_index).sum.to_f/@name_count.to_f
      rescue 
        @name_boost_from_item_type = "N/A" 
      end
      begin
        raise if @material_count == 0
        @material_boost_from_brand_name = @from_materials.pluck(:brand_name_index).sum.to_f/@material_count.to_f
      rescue
        @material_boost_from_brand_name = "N/A" 
      end
      begin
        raise if @item_type_count == 0
        @item_type_boost_from_brand_name = @from_item_types.pluck(:brand_name_index).sum.to_f/@item_type_count.to_f 
      rescue
        @item_type_boost_from_brand_name = "N/A"
      end
      begin 
        raise if @name_count == 0
        @name_boost_from_brand_name = @from_names.pluck(:brand_name_index).sum.to_f/@name_count.to_f
      rescue
        @name_boost_from_brand_name = "N/A"
      end
      # readjust variables to account for weakness of material attribute completeness
      @total_count = @brand_name_count+@item_type_count+@material_count+@name_count
      # get weighted variables
      begin 
        raise if @brand_name_count == 0 or @item_type_count == 0
        @item_type_adjusted_for_brand_name = @item_type_price_average*@brand_name_price_average/@brand_name_boost_from_item_type
      rescue 
        @item_type_adjusted_for_brand_name = "N/A" 
      end
      begin 
        raise if @item_type_count == 0 or @material_count == 0
        @item_type_adjusted_for_material = @item_type_price_average*@material_price_average/@material_boost_from_item_type
      rescue 
        @item_type_adjusted_for_material = "N/A"
      end
      begin 
        raise if @item_type_count == 0 or @name_count == 0
        @item_type_adjusted_for_name = @item_type_price_average*@name_price_average/@name_boost_from_item_type
      rescue
        @item_type_adjusted_for_name = "N/A" 
      end
      begin 
        raise if @brand_name_count == 0 or @item_type_count == 0
        @brand_name_adjusted_for_item_type = @brand_name_price_average*@item_type_price_average/@item_type_boost_from_brand_name 
      rescue 
        @brand_name_adjusted_for_item_type = "N/A" 
      end
      begin 
        raise if @brand_name_count == 0 or @material_count == 0
        @brand_name_adjusted_for_material = @brand_name_price_average*@material_price_average/@material_boost_from_brand_name 
      rescue 
        @brand_name_adjusted_for_material = "N/A" 
      end
      begin 
        raise if @brand_name_count == 0 or @name_count == 0
        @brand_name_adjusted_for_name = @brand_name_price_average*@name_price_average/@name_boost_from_brand_name 
      rescue 
        @brand_name_adjusted_for_name = "N/A" 
      end
      begin 
        raise if @item_type_count == 0 or @brand_name_count == 0
        @item_type_weighted_by_brand_name = @item_type_adjusted_for_brand_name*@brand_name_count 
      rescue 
        @item_type_weighted_by_brand_name = "N/A" 
      end
      begin 
        raise if @item_type_count == 0 or @material_count == 0
        @item_type_weighted_by_material = @item_type_adjusted_for_material*@material_count
      rescue 
        @item_type_weighted_by_material = "N/A" 
      end
      begin
        raise if @item_type_count == 0 or @name_count == 0
        @item_type_weighted_by_name = @item_type_adjusted_for_name*@name_count 
      rescue
        @item_type_weighted_by_name = "N/A"
      end
      begin 
        raise if @item_type_count == 0
        @item_type_weighted = @item_type_price_average*@item_type_count 
      rescue 
        @item_type_weighted = "N/A" 
      end
      begin 
        raise if @brand_name_count == 0 or @item_type_count == 0
        @brand_name_weighted_by_item_type = @brand_name_adjusted_for_item_type*@item_type_count
      rescue 
        @brand_name_weighted_by_item_type = "N/A" 
      end
      begin
        raise if @brand_name_count == 0 or @material_count == 0
        @brand_name_weighted_by_material = @brand_name_adjusted_for_material*@material_count
      rescue 
        @brand_name_weighted_by_material = "N/A"
      end
      begin 
        raise if @brand_name_count == 0 or @name_count == 0
        @brand_name_weighted_by_name = @brand_name_adjusted_for_name*@name_count 
      rescue
        @brand_name_weighted_by_name = "N/A"
      end
      begin 
        raise if @brand_name_count == 0
        @brand_name_weighted = @brand_name_price_average*@brand_name_count 
      rescue
        @brand_name_weighted = "N/A" 
      end
      # get final results
      weighted_item_type_adjustments = [@item_type_weighted_by_brand_name, @item_type_weighted_by_material, @item_type_weighted_by_name, @item_type_weighted].keep_if{|item|
        item.present? and item != "N/A"
      }
      begin @adjusted_and_weighted_item_type_average = weighted_item_type_adjustments.sum.to_f/@total_count rescue @adjusted_and_weighted_item_type_average = "N/A" end
      weighted_brand_name_adjustments = [@brand_name_weighted_by_item_type, @brand_name_weighted_by_material, @brand_name_weighted_by_name, @brand_name_weighted].keep_if{|item|
        item.present? and item != "N/A"
      }
      begin @adjusted_and_weighted_brand_name_average = weighted_brand_name_adjustments.sum.to_f/@total_count rescue @adjusted_and_weighted_brand_name_average = "N/A" end
      final_adjustments = [@adjusted_and_weighted_brand_name_average, @adjusted_and_weighted_item_type_average, @adjusted_and_weighted_item_type_average].keep_if{|item|
        item.present? and item != "N/A" and item > 0.1
      }
      begin @final_retail_price = final_adjustments.sum.to_f/final_adjustments.length rescue @final_retial_price = "N/A" end
      begin @used_price_factor = [(Table.used_item_type_hash[(Table.standardized_item_types[@item_type] || @item_type)] || 0.7),(Table.used_brand_name_hash[(Table.standardized_brand_names[@brand_name] || @brand_name)] || 0.7)].max rescue @used_price_factor = "N/A" end
      begin @final_used_price = @final_retail_price.to_f * (1.0-@used_price_factor).to_f rescue @final_used_price = "N/A" end
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
    new_record_count = 0
    product_type_seed = params[:product_type].upcase.gsub(/[^0-9A-Z ]/i,'').strip
    ([product_type_seed]+(Table.similar_item_type_hash[product_type_seed] || [])).compact.uniq.each do |product_type|
      # we only want single items so skip anything with 'SET' in it
      sem3.products_field( "search", "Furniture" )
      sem3.products_field( "name", "include" , product_type )
      product_type = product_type.upcase.gsub(/[^0-9A-Z ]/i,'').strip
      sem3.products_field( "name", "exclude" , ([params[:exclude]]+Table.badwords+(Table.badwords_by_item_type[product_type] || [])).compact.uniq.join(" ") ) 
      sem3.products_field( "search", params[:brand_name]) if params[:brand_name].present?
      sem3.products_field( "price", "gt", 20 )
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
              item_type: product_type_seed,
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
    end
    puts "New records created: #{new_record_count}"
    
    if new_record_count > 0
      #update brand name index
      brand_names = Table.order(:brand_name).select("brand_name").uniq.map(&:brand_name)
      table_brand_name_data = Table.joins("join tables as tables_2 on (tables.brand_name = tables_2.brand_name)").where('tables_2.price is not NULL and tables.brand_name is not NULL').select("tables.id, tables.brand_name, avg(tables_2.price) as avg_price").group("tables.id").collect{|t|
        [t.brand_name,t.avg_price]
      }.uniq.flatten
      table_brand_name_hash = Hash[table_brand_name_data.each_slice(2).to_a]    
      brand_names.each do |brand_name|
        tables = Table.where(brand_name: brand_name)
        next if tables.count == 0
        if tables.count%2 == 1 #odd
          median = tables.map(&:price).sort[tables.count/2] # median
        else #even and so > 1 since it can't be 0
          median = [tables.map(&:price).sort[tables.count/2],tables.map(&:price).sort[(tables.count+1)/2]].sum/2.0 # median
        end
        unless tables.update_all(brand_name_index: [median,median,table_brand_name_hash[brand_name]].sum/3.0)
          puts t.errors.messages.inspect
        end
      end
      puts "Brand name index updated"
      
      #update item type index
      item_types = Table.order(:item_type).select("item_type").uniq.map(&:item_type)
      table_item_types_data = Table.joins("join tables as tables_2 on (tables.item_type = tables_2.item_type)").where('tables_2.price is not NULL and tables.item_type is not NULL').select("tables.id, tables.item_type, avg(tables_2.price) as avg_price").group("tables.id").collect{|t|
        [t.item_type,t.avg_price]
      }.uniq.flatten
      table_item_type_hash = Hash[table_item_types_data.each_slice(2).to_a]    
      item_types.each do |item_type|
        tables = Table.where(item_type: item_type)
        next if tables.count == 0
        if tables.count%2 == 1 #odd
          median = tables.map(&:price).sort[tables.count/2] # median
        else #even and so > 1 since it can't be 0
          median = [tables.map(&:price).sort[tables.count/2],tables.map(&:price).sort[(tables.count+1)/2]].sum/2.0 # median
        end
        unless tables.update_all(item_type_index: [median,median,table_item_type_hash[item_type]].sum/3.0)
          puts t.errors.messages.inspect
        end
      end  
      puts "Item type index updated"
      puts "Total new records created: #{new_record_count}"
    end

    redirect_to tables_path
  end
  
  def update_tables_item_type_index
    item_types = Table.order(:item_type).select("item_type").uniq.map(&:item_type)
    table_item_types_data = Table.joins("join tables as tables_2 on (tables.item_type = tables_2.item_type)").where('tables_2.price is not NULL and tables.item_type is not NULL').select("tables.id, tables.item_type, avg(tables_2.price) as avg_price").group("tables.id").collect{|t|
      [t.item_type,t.avg_price]
    }.uniq.flatten
    table_item_type_hash = Hash[table_item_types_data.each_slice(2).to_a]    
    item_types.each do |item_type|
      tables = Table.where(item_type: item_type)
      next if tables.count == 0
      if tables.count%2 == 1 #odd
        median = tables.map(&:price).sort[tables.count/2] # median
      else #even and so > 1 since it can't be 0
        median = [tables.map(&:price).sort[tables.count/2],tables.map(&:price).sort[(tables.count+1)/2]].sum/2.0 # median
      end
      unless tables.update_all(item_type_index: [median,median,table_item_type_hash[item_type]].sum/3.0)
        puts t.errors.messages.inspect
      end
    end
    redirect_to :back, notice: "Update complete!"
  end
  
  def update_tables_brand_name_index
    brand_names = Table.order(:brand_name).select("brand_name").uniq.map(&:brand_name)
    table_brand_name_data = Table.joins("join tables as tables_2 on (tables.brand_name = tables_2.brand_name)").where('tables_2.price is not NULL and tables.brand_name is not NULL').select("tables.id, tables.brand_name, avg(tables_2.price) as avg_price").group("tables.id").collect{|t|
      [t.brand_name,t.avg_price]
    }.uniq.flatten
    table_brand_name_hash = Hash[table_brand_name_data.each_slice(2).to_a]    
    brand_names.each do |brand_name|
      tables = Table.where(brand_name: brand_name)
      next if tables.count == 0
      if tables.count%2 == 1 #odd
        median = tables.map(&:price).sort[tables.count/2] # median
      else #even and so > 1 since it can't be 0
        median = [tables.map(&:price).sort[tables.count/2],tables.map(&:price).sort[(tables.count+1)/2]].sum/2.0 # median
      end
      unless tables.update_all(brand_name_index: [median,median,table_brand_name_hash[brand_name]].sum/3.0)
        puts t.errors.messages.inspect
      end
    end
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

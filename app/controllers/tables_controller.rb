class TablesController < ApplicationController
  require 'semantics3'

  # Your Semantics3 API Credentials
  API_KEY = 'SEM3259890376C6C204B176FF18706FB87EB'
  API_SECRET = 'Y2JmZjY1NjU5NDM2YjljMmU3ZmQ4YjBhZjRjMGUwNTg'
  
  def appraisal_index
  end
  
  def appraisal_results
    table = params[:table]
    @error = false
    if table.present?
      table.has_key?(:brand_name) ? @brand_name = table[:brand_name].upcase.gsub(/[^0-9A-Z ]/i,'').strip : @brand_name = ""
      table.has_key?(:item_type) ? @item_type = table[:item_type].upcase.gsub(/[^0-9A-Z ]/i,'').strip : @item_type = ""
      table.has_key?(:item_type) ? @search = table.delete_if{|k,v| [:brand_name,:item_type].include?(k.to_sym) or v=="NO" or v=="NONE" or v.blank? }.collect{|k,v| v=="YES" ? k.upcase.sub("_"," ").gsub(/[^0-9A-Z ]/i,'').strip : v.gsub(/[^0-9A-Z ]/i,'').strip}.uniq : @search = []
      @from_brand_names = Table.where(([@brand_name]+(Table.similar_brand_name_hash[@brand_name] || [])).compact.collect{|brand_name| "brand_name ilike '%#{brand_name}%' or name ilike '%#{brand_name}%'"}.join(" or ")).order(:price) if @brand_name.present?
      @from_item_types = Table.where(([@item_type]+(Table.similar_item_type_hash[@item_type] || [])).compact.collect{|item_type| "item_type = '#{item_type}'"}.join(" or ")).order(:price) if @item_type.present?
      @from_search = Table.where(@search.compact.collect{|search| "name ilike '%#{search}%'"}.join(" or ")).order(:price) if @search.present?
      # prune 5% of outliers
      limit = @from_item_types.count/10
      brand_limit = @from_brand_names.count/10
      search_limit = @from_search.count/10
      begin @from_brand_names = @from_brand_names.limit(@from_brand_names.count-brand_limit/2).offset(brand_limit/2) if @from_brand_names.count > 20 rescue nil end
      begin @from_item_types = @from_item_types.limit(@from_item_types.count-limit/2).offset(limit/2) if @from_item_types.count > 20 rescue nil end
      begin @from_search = @from_search.limit(@from_search-search_limit/2).offset(search_limit/2) if @from_search.count > 20 rescue nil end
      @brand_name_count = (@from_brand_names || []).count
      @item_type_count = (@from_item_types || []).count
      @search_count = (@from_search || []).count
      # Average of mean AND median
      begin @brand_name_price_mean = @from_brand_names.map(&:price).sum/@brand_name_count rescue @brand_name_price_mean = "N/A" end
      begin (@brand_name_count%2==1) ? @brand_name_price_median = @from_brand_names[@brand_name_count/2].price : @brand_name_price_median = (@from_brand_names[@brand_name_count/2].price+@from_brand_names[@brand_name_count/2-1].price)/2.0 rescue @brand_name_price_median = "N/A" end
      begin @brand_name_price_average = [@brand_name_price_median,@brand_name_price_median,@brand_name_price_mean].sum/3.0 rescue @brand_name_price_average = "N/A" end
      begin @item_type_price_mean = @from_item_types.map(&:price).sum/@item_type_count rescue @item_type_price_mean = "N/A" end
      begin (@item_type_count%2==1) ? @item_type_price_median = @from_item_types[@item_type_count/2].price : @item_type_price_median = (@from_item_types[@item_type_count/2].price+@from_item_types[@item_type_count/2-1].price)/2.0 rescue @item_type_price_median = "N/A" end
      begin @item_type_price_average = [@item_type_price_median,@item_type_price_median,@item_type_price_mean].sum/3.0 rescue @item_type_price_average = "N/A" end
      begin @search_price_mean = @from_search.map(&:price).sum/@search_count rescue @search_price_mean = "N/A" end
      begin (@search_count%2==1) ? @search_price_median = @from_search[@search_count/2].price : @search_price_median = (@from_search[@search_count/2].price+@from_search[@search_count/2-1].price)/2.0 rescue @search_price_median = "N/A" end
      begin @search_price_average = [@search_price_median,@search_price_median,@search_price_mean].sum/3.0 rescue @search_price_average = "N/A" end
 
      # variables to standardize above variables
      begin 
        raise if @brand_name_count == 0
        @brand_name_boost_from_item_type = @from_brand_names.map(&:item_type_index).sum.to_f/@brand_name_count.to_f 
      rescue
        @brand_name_boost_from_item_type = "N/A"
      end
      begin
        raise if @item_type_count == 0
        @item_type_boost_from_brand_name = @from_item_types.map(&:brand_name_index).sum.to_f/@item_type_count.to_f 
      rescue
        @item_type_boost_from_brand_name = "N/A"
      end
      begin
        raise if @search_count == 0
        @search_boost_from_brand_name = @from_search.map(&:brand_name_index).sum.to_f/@search_count.to_f 
      rescue
        @search_boost_from_brand_name = "N/A"
      end
      begin
        raise if @search_count == 0
        @search_boost_from_item_type = @from_search.map(&:item_type_index).sum.to_f/@search_count.to_f 
      rescue
        @search_boost_from_item_type = "N/A"
      end
      # readjust variables to account for weakness of material attribute completeness
      @total_count = @brand_name_count+@item_type_count+@search_count
      # get weighted variables
      begin 
        raise if @brand_name_count == 0 or @item_type_count == 0
        @item_type_adjusted_for_brand_name = @item_type_price_average*@brand_name_price_average/@brand_name_boost_from_item_type
      rescue 
        @item_type_adjusted_for_brand_name = "N/A" 
      end
      begin 
        raise if @brand_name_count == 0 or @item_type_count == 0
        @brand_name_adjusted_for_item_type = @brand_name_price_average*@item_type_price_average/@item_type_boost_from_brand_name 
      rescue 
        @brand_name_adjusted_for_item_type = "N/A" 
      end
      begin 
        raise if @brand_name_count == 0 or @search_count == 0 
        @search_adjusted_for_brand_name = @search_price_average*@brand_name_price_average/@search_boost_from_brand_name
      rescue 
        @search_adjusted_for_brand_name = "N/A" 
      end
      begin 
        raise if @item_type_count == 0 or @search_count == 0
        @search_adjusted_for_item_type = @search_price_average*@item_type_price_average/@search_boost_from_item_type
      rescue 
        @search_adjusted_for_item_type = "N/A" 
      end
      begin 
        raise if @item_type_count == 0 or @brand_name_count == 0
        @item_type_weighted_by_brand_name = @item_type_adjusted_for_brand_name*@brand_name_count 
      rescue 
        @item_type_weighted_by_brand_name = "N/A" 
      end
      begin 
        raise if @item_type_count == 0
        @item_type_weighted = @item_type_price_average*@item_type_count 
      rescue 
        @item_type_weighted = "N/A" 
      end
      begin 
        raise if @search_count == 0 or @brand_name_count == 0
        @search_weighted_by_brand_name = @search_adjusted_for_brand_name*@brand_name_count 
      rescue 
        @search_weighted_by_brand_name = "N/A" 
      end
      begin 
        raise if @search_count == 0 or @item_type_count == 0
        @search_weighted_by_item_type = @search_adjusted_for_item_type*@item_type_count 
      rescue 
        @search_weighted_by_item_type = "N/A" 
      end
      begin 
        raise if @search_count == 0
        @search_weighted = @search_price_average*@search_count 
      rescue
        @search_weighted = "N/A" 
      end
      begin 
        raise if @brand_name_count == 0 or @item_type_count == 0
        @brand_name_weighted_by_item_type = @brand_name_adjusted_for_item_type*@item_type_count
      rescue 
        @brand_name_weighted_by_item_type = "N/A" 
      end
      begin 
        raise if @brand_name_count == 0
        @brand_name_weighted = @brand_name_price_average*@brand_name_count 
      rescue
        @brand_name_weighted = "N/A" 
      end
      # get final results
      weighted_item_type_adjustments = [@item_type_weighted_by_brand_name, @item_type_weighted].keep_if{|item|
        item.present? and item != "N/A"
      }
      begin @adjusted_and_weighted_item_type_average = weighted_item_type_adjustments.sum.to_f/(@total_count-@search_count) rescue @adjusted_and_weighted_item_type_average = "N/A" end
      weighted_brand_name_adjustments = [@brand_name_weighted_by_item_type, @brand_name_weighted].keep_if{|item|
        item.present? and item != "N/A"
      }
      begin @adjusted_and_weighted_brand_name_average = weighted_brand_name_adjustments.sum.to_f/(@total_count-@search_count) rescue @adjusted_and_weighted_brand_name_average = "N/A" end
      weighted_search_adjustments = [@search_weighted_by_brand_name, @search_weighted_by_item_type, @search_weighted].keep_if{|item|
        item.present? and item != "N/A"
      }
      begin @adjusted_and_weighted_search_average = weighted_search_adjustments.sum.to_f/@total_count rescue @adjusted_and_weighted_search_average = "N/A" end
      final_adjustments = [@adjusted_and_weighted_search_average,@adjusted_and_weighted_brand_name_average,@adjusted_and_weighted_brand_name_average,@adjusted_and_weighted_item_type_average,@adjusted_and_weighted_item_type_average,@adjusted_and_weighted_item_type_average].keep_if{|item|
        item.present? and item != "N/A" and item > 0.1
      }
      begin @final_retail_price = final_adjustments.sum.to_f/final_adjustments.length rescue @final_retail_price = "N/A" end
      #begin @used_price_factor = [(Table.used_item_type_hash[(Table.standardized_item_types[@item_type] || @item_type)] || 0.7),(Table.used_brand_name_hash[(Table.standardized_brand_names[@brand_name] || @brand_name)] || 0.4)].max rescue @used_price_factor = "N/A" end
      begin
        @used_price_factor = 0.4 
        (params[:table] || {}).each do |option,value|
          option = option.to_sym
          if Table.all_options.keys().include?(option) and value.present? and not [:brand_name, :item_type].include?(option)
            value = value.to_sym
            @used_price_factor -= (Table.all_options[option][value] || 0)
          end
        end
        @used_price_factor -= (Table.used_item_type_hash[(Table.standardized_item_types[@item_type] || @item_type)] || 0)
        @used_price_factor -= (Table.used_brand_name_hash[(Table.standardized_brand_names[@brand_name] || @brand_name)] || 0)
        @used_price_factor = [@used_price_factor,0.8].min
        @used_price_factor = [@used_price_factor,0.3].max
      rescue
        @used_price_factor = 0.4
        @error = true
      end
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
    ([product_type_seed]+((Table.similar_item_type_hash[product_type_seed] || [])-Table.all_item_types)).each do |product_type|
      puts "SEEDING #{product_type}"
      # we only want single items so skip anything with 'SET' in it
      sem3.products_field( "search", "Furniture" )
      sem3.products_field( "name", "include" , product_type )
      product_type = product_type.upcase.gsub(/[^0-9A-Z ]/i,'').strip
      sem3.products_field( "name", "exclude" , ([params[:exclude]]+Table.badwords+(Table.badwords_by_item_type[product_type] || [])).compact.uniq.join(" ") ) 
      sem3.products_field( "brand", params[:brand_name]) if params[:brand_name].present?
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
          
          puts price
          puts brand 
          
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
            if (table = Table.find_or_create_by(pHash))     
              new_record_count += 1 if table.new_record?
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
      Table.all_item_types.each do |item_type|
        tables = Table.where(item_type: ([item_type]+(Table.similar_item_type_hash[item_type] || []))).where("price is not null")
        next if tables.count == 0
        prices = tables.map(&:price).sort
        if tables.count%2 == 1 #odd
          median = prices[tables.count/2] # median
        else #even and so > 1 since it can't be 0
          median = [prices[tables.count/2],prices[(tables.count+1)/2]].sum/2.0 # median
        end
        mean = prices.sum/prices.length
        unless tables.update_all(item_type_index: [median,median,mean].sum/3.0)
          puts t.errors.messages.inspect
        end
      end 
      puts "Item type index updated"
      puts "Total new records created: #{new_record_count}"
    end

    redirect_to tables_path
  end
  
  def update_tables_item_type_index
    # MAKE USE OF THE MANUAL CONSOLIDATED ITEM TYPE LIST TO AGGREGATE SIMILAR ITEM TYPES
    Table.all_item_types.each do |item_type|
      tables = Table.where(item_type: ([item_type]+(Table.similar_item_type_hash[item_type] || []))).where("price is not null")
      next if tables.count == 0
      prices = tables.map(&:price).sort
      if tables.count%2 == 1 #odd
        median = prices[tables.count/2] # median
      else #even and so > 1 since it can't be 0
        median = [prices[tables.count/2],prices[(tables.count+1)/2]].sum/2.0 # median
      end
      mean = prices.sum/prices.length
      unless tables.update_all(item_type_index: [median,median,mean].sum/3.0)
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
    all_tables = Table
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

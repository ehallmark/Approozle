class Brand < ActiveRecord::Base
  has_many :tables
  
  def pricing_tier_hash
    hash = {
      0=> 'None',
      1=> 'Other',
      2=> '$1000 and Less',
      3=> '$1000 - $2500',
      4=> '$2500 - $5000',
      5=> '$5000 and Above'
    }
    return hash
  end
  
  def options_for_select
    return pricing_tier_hash.map{|k,v| [v,k] }
  end
  
  def pricing_tier_text
    pricing_tier_hash[pricing_tier]
  end
  
  def brand_attributes=(attributes)
    # Process the attributes hash
  end
  
end

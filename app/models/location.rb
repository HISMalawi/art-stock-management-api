class Location < ActiveRecord::Base
  self.table_name = "location"
  self.primary_key = "location_id"

  default_scope { where(retired: false) }
  
  def self.current_health_center
    location_id = GlobalProperty.find_by_property("current_health_center_id").property_value
    location = Location.find(location_id)
    return location
  end

end

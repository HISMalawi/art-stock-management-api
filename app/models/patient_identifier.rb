class PatientIdentifier < ActiveRecord::Base
  self.table_name = "patient_identifier"
  self.primary_key = "patient_identifier_id"

  default_scope { where(voided: 0) }
  def self.site_prefix
    site_prefix = GlobalProperty.find_by_property("site_prefix").property_value rescue ''
    return site_prefix
  end

end

class EncounterType < ActiveRecord::Base
  self.table_name = "encounter_type"
  self.primary_key = "encounter_type_id"

  default_scope { where(retired: 0) }
end

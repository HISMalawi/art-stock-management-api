class Encounter < ActiveRecord::Base
  self.table_name =  "encounter"
  self.primary_key = "encounter_id"

  default_scope { where(voided: 0) }
end

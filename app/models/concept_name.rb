class ConceptName < ActiveRecord::Base
  self.table_name = "concept_name"
  self.primary_key = "concept_name_id"

  default_scope { where(voided: 0) }
end

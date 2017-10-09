class DrugCms < ActiveRecord::Base
  self.table_name = "drug_cms"
  self.primary_key = "drug_inventory_id"

  default_scope { where(voided: 0) }
end

class OrderType < ActiveRecord::Base
  self.table_name =  "order_type"
  self.primary_key = "order_type_id"

  default_scope { where(retired: 0) }
end

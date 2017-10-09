class Order < ActiveRecord::Base
  self.table_name =  "orders"
  self.primary_key = "order_id"

  default_scope { where(voided: 0) }
end

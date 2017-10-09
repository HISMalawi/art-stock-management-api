class DrugOrder < ActiveRecord::Base
  self.table_name =  "drug_order"
  self.primary_key = "order_id"

  belongs_to :drug , -> { where retired: 0 }, foreign_key: "drug_inventory_id"
   
  def order
    @order ||= Order.find(order_id)
  end

  def duration
    ########We check if the non ARVs got the auto_expire_date moved forward to accormodate ARVs hanging pills
      if not order.discontinued_date.blank?
        auto_expire_date = order.discontinued_date.to_date
      else
        auto_expire_date = order.auto_expire_date.to_date
      end
    #########################################################################################################
    (auto_expire_date - order.start_date.to_date).to_i rescue nil
  end

end

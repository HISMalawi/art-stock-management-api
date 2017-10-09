class Drug < ActiveRecord::Base
  self.table_name = "drug"
  self.primary_key = "drug_id"

  default_scope { where(retired: 0) }

  def self.art_stock_info
    date = Date.today
    moh_products = DrugCms.all
    dispensing_encounter_type = EncounterType.find_by_name("DISPENSING")
    treatment_encounter_type = EncounterType.find_by_name("TREATMENT")
    amount_dispensed_concept = Concept.find_by_name('Amount dispensed')
    location_name = Location.current_health_center.name rescue ''

    drug_summary = {}
    self.update_stock_level_data(date, moh_products) #for updating stock record, average drug consumption
    drug_summary["dispensations"] =  self.get_dispensations(date, dispensing_encounter_type, amount_dispensed_concept)
    drug_summary["prescriptions"] = self.get_prescriptions(date, treatment_encounter_type)
    drug_summary["stock_level"] = self.get_stock_level(date, moh_products)
    drug_summary["consumption_rate"] = self.get_drug_consumption_rate(moh_products)
    drug_summary["relocations"] = self.get_relocations(date, moh_products)
    drug_summary["receipts"] = self.get_receipts(date, moh_products)
    drug_summary["supervision_verification"] = self.get_supervision_verification(date, moh_products)
    drug_summary["clinic_verification"] = self.get_clinic_verification(date, moh_products)
    supervision_verification_in_details = self.get_supervision_verification_in_details(date, moh_products)
    unless supervision_verification_in_details.blank?
      drug_summary["supervision_verification_in_details"] = supervision_verification_in_details
    end
    site_code = PatientIdentifier.site_prefix
    data = {
      :site_code => site_code,
      :date => date,
      :dispensations => drug_summary["dispensations"],
      :prescriptions => drug_summary["prescriptions"],
      :stock_level => drug_summary["stock_level"],
      :consumption_rate => drug_summary["consumption_rate"],
      :relocations => drug_summary["relocations"],
      :receipts => drug_summary["receipts"],
      :supervision_verification => drug_summary["supervision_verification"],
      :supervision_verification_in_details => supervision_verification_in_details,
      :location => location_name
    }

    SendResultsToCouchdb.add_record(data) #rescue ''
    #render :text => drug_summary.to_json and return we are no longer using this method for posting.
  end

  def self.update_stock_level_data(date, drugs)
    (drugs || []).each do |drug|
      Pharmacy.update_stock_record(drug.drug_inventory_id, date)
      Pharmacy.update_average_drug_consumption(drug.drug_inventory_id)
    end
  end

  def self.get_dispensations(date, encounter_type, concept)
    start_date = date.strftime('%Y-%m-%d 00:00:00')
    end_date = date.strftime('%Y-%m-%d 23:59:59')

    return ActiveRecord::Base.connection.select_all("SELECT count(e.patient_id) total_patients,
c.drug_inventory_id,sum(value_numeric) total FROM encounter e
INNER JOIN obs ON obs.encounter_id = e.encounter_id
INNER JOIN drug_order d ON d.order_id = obs.order_id
INNER JOIN drug_cms c ON c.drug_inventory_id = obs.value_drug
WHERE encounter_type = #{encounter_type.id} AND encounter_datetime
BETWEEN '#{start_date}' AND '#{end_date}' AND e.voided = 0
AND obs.voided = 0 AND obs.concept_id = #{concept.id}
GROUP BY value_drug;")

  end

  def self.get_prescriptions(date, encounter_type)
    start_date = date.strftime('%Y-%m-%d 00:00:00')
    end_date = date.strftime('%Y-%m-%d 23:59:59')

    return ActiveRecord::Base.connection.select_all("SELECT count(e.patient_id) total_patients,do.drug_inventory_id,
SUM((ABS(DATEDIFF(o.auto_expire_date, o.start_date)) * do.equivalent_daily_dose)) as total
FROM encounter e INNER JOIN orders o
ON e.encounter_id = o.encounter_id
INNER JOIN drug_order do ON o.order_id = do.order_id
INNER JOIN drug_cms d ON do.drug_inventory_id = d.drug_inventory_id
WHERE e.encounter_type = #{encounter_type.id}
AND e.encounter_datetime BETWEEN '#{start_date}'
AND '#{end_date}' AND e.voided = 0 GROUP BY do.drug_inventory_id")

  end

  def self.get_stock_level(date, drugs)
    stock_levels = {}
    (drugs || []).each do |drug|

      stock_levels[drug.drug_inventory_id] = Pharmacy.drug_stock_on(drug.drug_inventory_id, date)
    end

    return stock_levels
  end

  def self.get_drug_consumption_rate(drugs)
    consumption_rate = {}
    (drugs || []).each do |drug|

      consumption_rate[drug.drug_inventory_id] = Pharmacy.latest_drug_rate(drug.drug_inventory_id)
    end

    return consumption_rate
  end

  def self.get_relocations(date, drugs)
    drug_relocations = {}
    (drugs || []).each do |drug|
      drug_relocations[drug.drug_inventory_id] = Pharmacy.relocated(drug.drug_inventory_id, date, date)
    end

    return drug_relocations
  end

  def self.get_receipts(date, drugs)
    drug_receipts = {}
    (drugs || []).each do |drug|
      drug_receipts[drug.drug_inventory_id] = Pharmacy.receipts(drug.drug_inventory_id, date, date)
    end

    return drug_receipts
  end

  def self.get_supervision_verification(date, drugs)
    drug_supervision_verification = {}
    (drugs || []).each do |drug|
      drug_supervision_verification[drug.drug_inventory_id] = Pharmacy.verify_closing_stock_count(drug.drug_inventory_id,(date - 1.day ),date,"supervision", false)
    end

    return drug_supervision_verification
  end

  def self.get_clinic_verification(date, drugs)
    drug_clinic_verification = {}
    (drugs || []).each do |drug|
      drug_clinic_verification[drug.drug_inventory_id] = Pharmacy.verify_closing_stock_count(drug.drug_inventory_id,(date - 1.day),date, "clinic", false)
    end

    return drug_clinic_verification
  end

  def self.get_supervision_verification_in_details(date, drugs)
    drug_supervision_verification = {}
    (drugs || []).each do |drug|
      drug_supervision_verification[drug.drug_inventory_id] = Pharmacy.physical_verified_stock(drug.drug_inventory_id,date)
    end

    return drug_supervision_verification
  end

end

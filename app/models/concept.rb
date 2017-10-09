class Concept < ActiveRecord::Base
  self.table_name = "concept"
  self.primary_key = "concept_id"

  default_scope { where(retired: false) }
  def self.find_by_name(concept_name)
    #Concept.find(:first, :joins => 'INNER JOIN concept_name on concept_name.concept_id = concept.concept_id', :conditions => ["concept.retired = 0 AND concept_name.voided = 0 AND concept_name.name =?", "#{concept_name}"])
    Concept.joins("INNER JOIN concept_name ON concept_name.concept_id = concept.concept_id").where("concept_name.name = '#{concept_name}' AND concept_name.voided = 0").first
  end
  
end

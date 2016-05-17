class ArkAssignActor
  def initialize
  end
  
  def assign_missing_arks
    GenericFile.all.each do |gf| assign_missing_object_ark(gf) end
    Collection.all.each do |c| assign_missing_object_ark(c) end
  end
  
  private
  
    def assign_missing_object_ark(object)
      unless object.local_ark.present?
        object.identifier += ["ark:/#{object.ark_naan}/#{object.id}"]
        object.save
      end
    end
end
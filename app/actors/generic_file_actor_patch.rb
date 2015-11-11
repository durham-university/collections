# Monkey patch to prevent setting creator automatically. Patch applied in
# /config/application.rb
module GenericFileActorPatch
  def create_metadata(*args)
    creator_was = generic_file.creator.to_a
    super(*args) do |file|
      file.creator = creator_was
      yield(file) if block_given?
    end
  end
end

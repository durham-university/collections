namespace :ark do
  desc "Adds ark identifiers to objects which don't have them yet"
  task :create_missing => :environment do 
    raise 'No ark_naan in GenericFile' unless GenericFile.ark_naan.present?
    raise 'No ark_naan in Collection' unless Collection.ark_naan.present?
    raise 'Different ark_naan for GenericFile and Collection, this is probably not intended' if GenericFile.ark_naan!=Collection.ark_naan
    puts "About to assign an ARK identifier to all resources not having one yet."
    puts "Configured ARK NAAN is #{GenericFile.ark_naan}."
    puts "Continue? [y/n]"
    input = STDIN.gets
    if input.downcase == "y\n"
      puts "Assigning ARKs"
      ArkAssignActor.new.assign_missing_arks 
      puts "Done"
    else
      puts "Aborting"
    end
  end
end
FactoryGirl.define do
  factory :batch do
    generic_files { [ FactoryGirl.create(:generic_file,title:['File_1']), FactoryGirl.create(:generic_file,title:['File_2'])] }
  end
end

require 'rails_helper'

RSpec.shared_examples "ordered property" do
  before {
    class Foo < ActiveFedora::Base
    end
    Foo.class_eval <<-CODE, __FILE__, __LINE__ + 1
      include #{concern}
      #{macro} :text, predicate: ::RDF::URI.new('http://www.example.com/test') do |index|
        index.as :stored_searchable
      end
    CODE
  }
  after {
    Object.send(:remove_const,:Foo)
  }

  let( :wrapper ) { "text#{wrapper_suffix}".to_sym }
  let( :set_wrapper) { "#{wrapper}=".to_sym }

  subject { Foo.new }

  describe "setter and getter" do
    it "accepts an array and returns it" do
      subject.text=['aaa','bbb']
      expect(subject.text).to eql ['aaa','bbb']
    end

    it "resetting the value" do
      subject.text=['aaa','bbb']
      subject.text=['ccc','ddd','eee']
      expect(subject.text).to eql ['ccc','ddd','eee']
    end

    it "accepts empty arrays" do
      subject.text=['aaa','bbb']
      subject.text=[]
      expect(subject.text).to eql []
    end
  end

  describe "persistence" do
    it "saves and loads" do
      subject.text=['aaa','bbb']
      subject.save
      subject.reload
      expect(subject.text).to eql ['aaa','bbb']
    end

    it "resets the value" do
      subject.text=['aaa','bbb']
      subject.save
      subject.reload
      subject.text=['ccc']
      subject.save
      subject.reload
      expect(subject.text).to eql ['ccc']
    end

    it "preserves ordering" do
      subject.text=['aaa','bbb','ccc']
      wrapped=subject.send(wrapper).to_a
      subject.send(set_wrapper, [ wrapped[2],wrapped[0],wrapped[1] ] )
      subject.save
      subject.reload
      expect(subject.text).to eql ['aaa','bbb','ccc']
    end
  end

  describe "indexing" do
    it "adds the value to solr" do
      subject.text=['aaa','bbb']
      expect(subject.to_solr['text_tesim']).to eql ['aaa','bbb']
    end
  end
end

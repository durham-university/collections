require 'rails_helper'

RSpec.describe HydraDurham::IdentifierNormalisation do
  before {
    class Foo < ActiveFedora::Base
      include HydraDurham::IdentifierNormalisation
      property :identifier, predicate: ::RDF::URI.new('http://www.example.com/ns#identifier')
      property :related_url, predicate: ::RDF::URI.new('http://www.example.com/ns#related_url')
    end
  }
  after {
    Object.send(:remove_const,:Foo)
  }
  let(:obj) { Foo.new(identifier: ['http://dx.doi.org/12345/987654321','http://arxiv.org/abs/121212121212'], related_url: ['http://dx.doi.org/12345/01010101010','Something else'] )}

  describe "before validation callback" do
    it "calls normalisation before saving" do
      expect(obj).to receive(:normalise_record_identifiers!).and_call_original
      expect(obj).to receive(:normalise_record_related_url!).and_call_original
      obj.save
      expect(obj.reload.identifier).to match_array(['doi:12345/987654321','arxiv:121212121212'])
      expect(obj.reload.related_url).to match_array(['doi:12345/01010101010','Something else'])
    end
  end

  describe "#normalise_record_identifiers!" do
    it "normalises and sets identifiers" do
      obj.normalise_record_identifiers!
      expect(obj.identifier).to match_array(['doi:12345/987654321','arxiv:121212121212'])
    end
  end

  describe "#normalise_record_related_url!" do
    it "normalises and sets related_url" do
      obj.normalise_record_related_url!
      expect(obj.related_url).to match_array(['doi:12345/01010101010','Something else'])
    end
  end

  describe "::normalise_identifier" do
    [
      { label: 'doi', test: 'http://dx.doi.org/12345/987654321', expected: 'doi:12345/987654321'},
      { label: 'arxiv', test: 'http://arxiv.org/abs/121212121212', expected: 'arxiv:121212121212'},
      { label: 'isbn', test: 'ISBN:1234567890', expected: 'isbn:1234567890'},
      { label: 'unknown', test: 'http://www.example.com/ident/334433', expected: 'http://www.example.com/ident/334433'}
    ].each do |test|
      it "normalises #{test[:label]} identifiers" do
        expect(Foo.normalise_identifier(test[:test])).to eql(test[:expected])
      end
      it "is stable with #{test[:label]} identifiers" do
        expect(Foo.normalise_identifier(test[:expected])).to eql(test[:expected])
      end
    end

  end

  describe "::identifier_link" do
    [
      { label: 'doi', test: 'doi:12345/987654321', expected: 'http://dx.doi.org/12345/987654321'},
      { label: 'arxiv', test: 'arxiv:121212121212', expected: 'http://arxiv.org/abs/121212121212'},
      { label: 'http', test: 'http://www.example.com/12345', expected: 'http://www.example.com/12345'},
      { label: 'https', test: 'https://www.example.com/12345', expected: 'https://www.example.com/12345'}
    ].each do |test|
      it "links #{test[:label]} identifiers" do
        expect(Foo.identifier_link(test[:test])).to eql(test[:expected])
      end
    end
    it "returns nil for unknown identifiers" do
      expect(Foo.identifier_link('test:12345')).to be_nil
    end
  end

end

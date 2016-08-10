require 'rails_helper'

RSpec.describe HydraDurham::DownloadTunnelBehaviour, type: :controller do
  before {
    class FooController < ApplicationController
      include HydraDurham::DownloadTunnelBehaviour
    end
  }
  after {
    Object.send(:remove_const,:FooController)
  }
  let(:tunnel) { FooController.new }
  
  describe "#show" do
    it "raises error when download_url is nil" do
      expect(tunnel).to receive(:download_url).and_return(nil)
      expect {
        tunnel.show
      } .to raise_error(ActionController::RoutingError)
    end
    it "calls pipe_url when download_url is present" do
      expect(tunnel).to receive(:download_url).at_least(:once).and_return('http://test:3000/test/12345')
      expect(tunnel).to receive(:pipe_url).with('http://test:3000/test/12345')
      tunnel.show
    end
  end
  
  describe "#set_response_headers" do
    let(:in_response){ double('in_response', header: { 'Content-Type' => 'test/testtype', 'Content-Length' => '1234', 'Some-Other-Header' => 'moo'}) }
    let(:out_response){ double('out_response', headers: {} ) }
    before {
      expect(out_response).to receive(:status=).with(200)
    }
    it "copies some headers" do
      allow(tunnel).to receive(:response).and_return(out_response)
      tunnel.send(:set_response_headers,in_response)
      expect(out_response.headers).to eql({'Content-Type' => 'test/testtype', 'Content-Length' => '1234'})
    end
  end
  
  describe "#pipe_response" do
    let(:in_response){ 
      double('in_response').tap do |resp|
        allow(resp).to receive(:read_body).and_yield('test contents')
      end
    }
    let(:out_response){ double('out_response', stream: StringIO.new ) }
    it "sets response headers and pipes the response" do
      allow(tunnel).to receive(:response).and_return(out_response)
      expect(tunnel).to receive(:set_response_headers).with(in_response)
      tunnel.send(:pipe_response, in_response)
      expect(out_response.stream.string).to eql('test contents')
    end
  end
  
  describe "#pipe_url" do
    it "follows redirects and calls #pipe_url" do
      allow(Net::HTTP).to receive(:start)
      expect(Net::HTTP).to receive(:start).with('test1', 80, any_args).and_yield(
        double('http1').tap do |mock|
          allow(mock).to receive(:request) do |req,&block|
            expect(req.method).to eql('GET')
            expect(req.path).to eql('/test1')
            block.call(double('response1', code: '302', header: {'Location' => 'http://test2/test2'}))
          end
        end
      )
      expect(Net::HTTP).to receive(:start).with('test2', 80, any_args).and_yield(
        double('http2').tap do |mock|
          allow(mock).to receive(:request) do |req,&block|
            expect(req.method).to eql('GET')
            expect(req.path).to eql('/test2')
            block.call(double('response2', code: '200'))
          end
        end
      )
      expect(tunnel).to receive(:pipe_response)
      tunnel.send(:pipe_url,'http://test1/test1')
    end
  end
end
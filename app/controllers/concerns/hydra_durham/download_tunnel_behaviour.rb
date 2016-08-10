module HydraDurham
  module DownloadTunnelBehaviour
    extend ActiveSupport::Concern
    
    included do
      before_action :authorize_tunnel_download, only: [:show]
    end
    
    def show
      raise ActionController::RoutingError, 'Not Found' unless download_url.present?
      pipe_url(download_url)
    end
    
    protected
    
      def set_response_headers(in_response)
        response.status = 200
        ['Content-Type', 'Content-Disposition', 'Content-Transfer-Encoding', 'Content-Length'].each do |header|
          response.headers[header] = in_response.header[header] if in_response.header.key?(header)
        end
      end
      
      def send_error(in_response)
        response.status = in_response.code.to_i
        response.stream.write("Error retrieving file #{in_response.code}")
        response.stream.close
      end
      
      def pipe_response(in_response)
        set_response_headers(in_response)
        in_response.read_body do |chunk|
          response.stream.write chunk
        end
        response.stream.close
      end
      
      def pipe_url(url, tried=[])
        uri = URI(url)
        options = { use_ssl: uri.scheme == 'https' }
        options[:verify_mode] = OpenSSL::SSL::VERIFY_NONE if no_verify_certificate
        
        Net::HTTP.start(uri.host, uri.port, options) do |http|
          http.request(Net::HTTP::Get.new(uri.path)) do |resp|
            if resp.code == '200'
              pipe_response(resp)
            elsif ['301', '302', '303', '307'].include?(resp.code) # redirects
              if tried.include?(resp.header['Location']) || tried.length>5 # detect redirect loops
                send_error(resp) 
              else
                pipe_url(resp.header['Location'], tried + [url])
              end
            else
              send_error(resp)
            end
          end
        end
      end
      
      def no_verify_certificate
        # return true to disable certificate verification, useful for debugging
        false
      end
    
      def download_url
        # Override this, returning nil will give a 404
        nil
      end
      
      def authorize_tunnel_download
        # Override this to something that doesn't raise an error if the user
        # can download the file.
        raise 'Not authorized to download selected file'
      end
    
  end
end
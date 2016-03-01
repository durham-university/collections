class SchmitDownloadsController < ApplicationController
  include HydraDurham::DownloadTunnelBehaviour
  
  protected
  
    def download_url
      return nil unless /^ark:\/[0-9]{5}\/[a-z0-9]+\.(pdf|xml)$/.match(params[:id])
      SCHMIT_CONFIG['schmit_url']+"id/#{params[:id]}"
    end
    
    def authorize_tunnel_download
      # Schmit Downloads controller won't let anonymous users download restricted
      # files so no need to do any further checks here. If the normal Schmit route
      # reaches the file using an anonymous user, then we can pass it on.
    end
  
end
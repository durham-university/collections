class DownloadsController < ApplicationController
  include Sufia::DownloadsControllerBehavior

  def file_name
    return params[:filename] if params[:filename].present?
    base = asset.filename.try(:first) || asset.label || 'unnamed_file'
    extension = ''
    ind = base.rindex('.')
    if ind
      extension = base[ind..-1].downcase
      base = base[0..(ind-1)]
    end
    file_type=''
    if params[:file] && params[:file] != self.class.default_file_path
      file_type = "-#{params[:file]}"
      extension = '' # don't add extension to thumbnails or other derivatives
    end
    version = asset.content.latest_version.label

    "#{base}-#{asset.id}-#{version}#{file_type}#{extension}".gsub(/[^a-zA-Z0-9_\.-]/,'_')
  end
end

# Returns an array containing the vhost 'CoSign service' value and URL
Sufia.config do |config|

  config.fits_to_desc_mapping= {
    file_title: :title,
    file_author: :creator
  }

  config.max_days_between_audits = 7

  config.max_notifications_for_dashboard = 5

  config.cc_licenses = {
    'All rights reserved' => 'All rights reserved',
    'Open Data Commons - Open Database (ODC-ODbL)' => 'http://opendatacommons.org/licenses/odbl/1.0/',
    'Creative Commons Attribution 4.0 International (CC BY)' => 'http://creativecommons.org/licenses/by/4.0/',
    'Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA)' => 'http://creativecommons.org/licenses/by-sa/4.0/',
    'Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC)' => 'http://creativecommons.org/licenses/by-nc/4.0/',
    'Creative Commons Attribution-NoDerivs 4.0 International (CC BY-ND)' => 'http://creativecommons.org/licenses/by-nd/4.0/',
    'Creative Commons Attribution-NonCommercial-NoDerivs 4.0 International (CC BY-NC-ND)' => 'http://creativecommons.org/licenses/by-nc-nd/4.0/',
    'Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA)' => 'http://creativecommons.org/licenses/by-nc-sa/4.0/',
    'Creative Commons Public Domain Dedication (CC0 1.0)' => 'http://creativecommons.org/publicdomain/zero/1.0/',
    'Public Domain Mark 1.0' => 'http://creativecommons.org/publicdomain/mark/1.0/'
  }

  config.cc_licenses_reverse = Hash[*config.cc_licenses.to_a.flatten.reverse]

  config.resource_types = {
#    "Article" => "Article",
    "Audio" => "Audio",
#    "Book" => "Book",
#    "Capstone Project" => "Capstone Project",
#    "Conference Proceeding" => "Conference Proceeding",
    "Dataset" => "Dataset",
#    "Dissertation" => "Dissertation",
    "Image" => "Image",
#    "Journal" => "Journal",
    "Map or Cartographic Material" => "Map or Cartographic Material",
#    "Masters Thesis" => "Masters Thesis",
#    "Part of Book" => "Part of Book",
#    "Poster" => "Poster",
#    "Presentation" => "Presentation",
#    "Project" => "Project",
#    "Report" => "Report",
#    "Research Paper" => "Research Paper",
    "Software or Program Code" => "Software or Program Code",
    "Video" => "Video",
    "Other" => "Other",
  }

  config.resource_types_to_schema = {
    "Article" => "http://schema.org/Article",
    "Audio" => "http://schema.org/AudioObject",
    "Book" => "http://schema.org/Book",
    "Capstone Project" => "http://schema.org/CreativeWork",
    "Conference Proceeding" => "http://schema.org/ScholarlyArticle",
    "Dataset" => "http://schema.org/Dataset",
    "Dissertation" => "http://schema.org/ScholarlyArticle",
    "Image" => "http://schema.org/ImageObject",
    "Journal" => "http://schema.org/CreativeWork",
    "Map or Cartographic Material" => "http://schema.org/Map",
    "Masters Thesis" => "http://schema.org/ScholarlyArticle",
    "Part of Book" => "http://schema.org/Book",
    "Poster" => "http://schema.org/CreativeWork",
    "Presentation" => "http://schema.org/CreativeWork",
    "Project" => "http://schema.org/CreativeWork",
    "Report" => "http://schema.org/CreativeWork",
    "Research Paper" => "http://schema.org/ScholarlyArticle",
    "Software or Program Code" => "http://schema.org/Code",
    "Video" => "http://schema.org/VideoObject",
    "Other" => "http://schema.org/CreativeWork",
  }

  config.resource_types_to_datacite = {
    "Audio" => "Sound",
    "Collection" => "Collection",
    "Dataset" => "Dataset",
    "Image" => "Image",
    "Poster" => "Other",
    "Presentation" => "Other",
    "Software or Program Code" => "Software",
    "Video" => "Audiovisual",
    "Model" => "Model",
    "Physical Object" => "PhysicalObject",
    "Service" => "Service",
    "Workflow" => "Workflow",
    "Other" => "Other",
  }

  config.contributor_roles = {
    "Creator" => "http://id.loc.gov/vocabulary/relators/cre",
    "Contact person" => "http://id.loc.gov/vocabulary/relators/mdc",
    "Data collector" => "http://id.loc.gov/vocabulary/relators/col",
    "Data curator" => "http://id.loc.gov/vocabulary/relators/cur",
    "Editor" => "http://id.loc.gov/vocabulary/relators/edt"
  }
  config.contributor_roles_reverse = Hash[*config.contributor_roles.to_a.flatten.reverse]

  config.resource_types_to_datacite_reverse = Hash[*config.resource_types_to_datacite.to_a.flatten.reverse]


  config.permission_levels = {
    "Choose Access"=>"none",
    "View/Download" => "read",
    "Edit" => "edit"
  }

  config.owner_permission_levels = {
    "Edit" => "edit"
  }

  config.queue = Sufia::Resque::Queue

  # Enable displaying usage statistics in the UI
  # Defaults to FALSE
  # Requires a Google Analytics id and OAuth2 keyfile.  See README for more info
  config.analytics = false

  # Specify a Google Analytics tracking ID to gather usage statistics
  # config.google_analytics_id = 'UA-99999999-1'

  # Specify a date you wish to start collecting Google Analytic statistics for.
  # config.analytic_start_date = DateTime.new(2014,9,10)

  # Where to store tempfiles, leave blank for the system temp directory (e.g. /tmp)
  # config.temp_file_base = '/home/developer1'

  # Specify the form of hostpath to be used in Endnote exports
  # config.persistent_hostpath = 'http://localhost/files/'

  # If you have ffmpeg installed and want to transcode audio and video uncomment this line
  # config.enable_ffmpeg = true

  # Sufia uses NOIDs for files and collections instead of Fedora UUIDs
  # where NOID = 10-character string and UUID = 32-character string w/ hyphens
  # config.enable_noids = true

  # Specify a different template for your repository's NOID IDs
  # config.noid_template = ".reeddeeddk"

  # Specify the prefix for Redis keys:
  # config.redis_namespace = "sufia"

  # Specify the path to the file characterization tool:
  config.fits_path = "/opt/fits/fits.sh"

  # Specify how many seconds back from the current time that we should show by default of the user's activity on the user's dashboard
  # config.activity_to_show_default_seconds_since_now = 24*60*60

  # Specify a date you wish to start collecting Google Analytic statistics for.
  # Leaving it blank will set the start date to when ever the file was uploaded by
  # NOTE: if you have always sent analytics to GA for downloads and page views leave this commented out
  # config.analytic_start_date = DateTime.new(2014,9,10)
  #
  # Method of converting ids into URIs for storage in Fedora
  # config.translate_uri_to_id = lambda { |uri| uri.to_s.split('/')[-1] }
  # config.translate_id_to_uri = lambda { |id|
  #      "#{ActiveFedora.fedora.host}#{ActiveFedora.fedora.base_path}/#{Sufia::Noid.treeify(id)}" }

  # If browse-everything has been configured, load the configs.  Otherwise, set to nil.
  begin
    if defined? BrowseEverything
      config.browse_everything = BrowseEverything.config
    else
      Rails.logger.warn "BrowseEverything is not installed"
    end
  rescue Errno::ENOENT
    config.browse_everything = nil
  end

end

Date::DATE_FORMATS[:standard] = "%-d %B %Y"
Time::DATE_FORMATS[:standard] = "%-d %B %Y, %H:%m:%S"

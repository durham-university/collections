class UpdateDataciteJob < ActiveFedoraIdBasedJob



  attr_accessor :user_key
  attr_accessor :do_metadata
  attr_accessor :do_mint
  attr_accessor :retry_count
  attr_accessor :object_path

  def initialize(id,user,do_metadata: true,do_mint: false,retry_count: 5,object_path: nil)
    super(id)
    self.user_key=( user.is_a? User) ? (user.user_key) : user
    self.do_metadata=do_metadata
    self.do_mint=do_mint
    self.retry_count=retry_count
    self.object_path= object_path || (Rails.application.routes.url_helpers.method(object.class.name.underscore+'_path').call(object) )
    @object=nil # must reset this otherwise the job can't be serialised for Resque
  end

  def queue_name
    :update_datacite
  end

  def send_message(title,message)
    user=User.find_by_user_key user_key
    user.send_message(user,message, title, sanitize_text = false )
  end

  def link_to_object
    title=( (object.title.is_a? Array) ? (object.title.first) : (object.title) ).to_s
    ActionController::Base.helpers.link_to title, object_path
  end

  def send_success_message
    message=if @do_mint
      "DataCite metadata updated and DOI minted for #{link_to_object}"
    else
      "DataCite metadata updated for #{link_to_object}"
    end
    send_message('DataCite update complete',message)
  end

  def send_failed_message(error)
    message=if @do_mint
      "DataCite metadata updated and DOI minting failed for #{link_to_object}."
    else
      "DataCite metadata updated failed for #{link_to_object}."
    end
    if error
      message << "<br />Error message : #{error}"
    end
    send_message('DataCite update FAILED',message)
  end

  def remove_doi
    full_doi="doi:#{object.mock_doi}"
    if object.identifier.index full_doi
      object.identifier.delete full_doi
      object.update( { identifier: object.identifier } )
    end
  end

  def run
    # Accessing the object will raise an ObjectNotFoundError if it doesn't exist,
    # no need to check for that specifically
    raise "Resource doesn't support DOI functionality" if not object.respond_to? :doi

    begin
      datacite = Datacite.new
      if @do_metadata
        datacite.metadata(object.doi_metadata_xml)
        # set do_metadata to false so that if minting fails and we end up retrying
        # we don't send metadata again
        self.do_metadata=false
      end
      if @do_mint
        datacite.mint(object.doi_landing_page,object.mock_doi)
      end
      send_success_message
    rescue Datacite::DataciteUpdateException=>e
      if retry_count>0 and e.http_code and e.http_code>=500 and e.http_code<=599
        # TODO: Can we add a delay here?
        # TODO: How to add a log message that the job failed but will be retried later?
        Sufia.queue.push(UpdateDataciteJob.new(id,user_key,do_metadata: do_metadata, do_mint: do_mint, retry_count: retry_count-1, object_path: object_path ))
      else
        send_failed_message e
        remove_doi if @do_mint
        raise e
      end
    end
  end
end

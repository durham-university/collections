class UpdateDataciteJob < ActiveFedoraIdBasedJob



  attr_accessor :user_key
  attr_accessor :do_metadata
  attr_accessor :do_mint
  attr_accessor :retry_count
  attr_accessor :object_path
  attr_accessor :retry_notification_sent

  def initialize(id,user,do_metadata: true,do_mint: false,retry_count: 5,object_path: nil, retry_notification_sent: false)
    super(id)
    self.user_key=( user.is_a? User) ? (user.user_key) : user
    self.do_metadata=do_metadata
    self.do_mint=do_mint
    self.retry_count=retry_count
    self.object_path= object_path || (Rails.application.routes.url_helpers.method(object.class.name.underscore+'_path').call(object) )
    self.retry_notification_sent = retry_notification_sent
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

  def send_retry_message
    send_message('Retrying DataCite update','Datacite update failed but will be retried later.')
  end

  def remove_doi
    full_doi="doi:#{object.mock_doi}"
    if object.identifier.index full_doi
      object.identifier.delete full_doi
      object.update( { identifier: object.identifier } )
    end
  end

  def save_doi
    if object.respond_to? :date_modified
      object.date_modified = DateTime.now
    end

    # It is important to set this before saving. Otherwise the save would trigger
    # another datacite update and go in an infinite loop.
    object.skip_update_datacite = true
    begin
      object.save
    ensure
      object.skip_update_datacite = false
    end
  end

  # Sends data to Datacite and updates the object as needed. Does not send
  # notifications or add any other jobs to Resque or retry in case of network
  # problems
  def do_update
    datacite = Datacite.new
    if @do_metadata

      object.add_doi
      object.doi_published = DateTime.now if not object.doi_published

      metadata=object.doi_metadata
      datacite.metadata(object.doi_metadata_xml(metadata))

      object.datacite_document=metadata.to_json

      save_doi

      # set do_metadata to false so that if minting fails and we end up retrying
      # we don't send metadata again
      self.do_metadata=false
    end
    if @do_mint
      datacite.mint(object.doi_landing_page,object.mock_doi)
    end
  end

  def run
    # Accessing the object will raise an ObjectNotFoundError if it doesn't exist,
    # no need to check for that specifically
    raise "Resource doesn't support DOI functionality" if not object.respond_to? :doi

    begin
      do_update
      send_success_message
    rescue Exception=>e
      if retry_count>0 and e.is_a? Datacite::DataciteUpdateException and e.http_code and e.http_code>=500 and e.http_code<=599
        # TODO: Can we add a delay here?
        if not @retry_notification_sent
          send_retry_message
        end
        Sufia.queue.push(UpdateDataciteJob.new(id,user_key,
                                    do_metadata: do_metadata,
                                    do_mint: do_mint,
                                    retry_count:
                                    retry_count-1,
                                    object_path: object_path,
                                    retry_notification_sent: true
                                    ))
      else
        send_failed_message e
        raise e
      end
    end
  end
end

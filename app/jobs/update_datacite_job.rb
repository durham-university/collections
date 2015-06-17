class UpdateDataciteJob < ActiveFedoraIdBasedJob

  attr_accessor :do_metadata
  attr_accessor :do_mint
  attr_accessor :retry_count

  def initialize(id,do_metadata: true,do_mint: false,retry_count: 5)
    super(id)
    self.do_metadata=do_metadata
    self.do_mint=do_mint
    self.retry_count=retry_count
  end

  def queue_name
    :update_datacite
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
    rescue Exception=>e
      # TODO: only retry HTTP 50X exceptions, or something
      if retry_count>0
        # TODO: Can we add a delay here?
        # TODO: How to add a log message that the job failed but will be retried later?
        Sufia.queue.push(UpdateDataciteJob.new(id,do_metadata: do_metadata, do_mint: do_mint, retry_count: retry_count-1))
      else
        raise e
      end
    end
  end
end

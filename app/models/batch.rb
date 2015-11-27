# This file is copied from Sufia with the addition of proper locking in
# safe_create. This should be made a pull request to Sufia later.
# See comments in app/services/sufia/lock_manager.rb

class Batch < ActiveFedora::Base
  include Hydra::AccessControls::Permissions
  include Sufia::ModelMethods
  include Sufia::Noid

  has_many :generic_files, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf

  property :creator, predicate: ::RDF::DC.creator
  property :title, predicate: ::RDF::DC.title
  property :status, predicate: ::RDF::DC.type

  def self.find_or_create(id)
    Batch.find(id)
  rescue ActiveFedora::ObjectNotFoundError
    safe_create(id)
  end

  # This method handles race conditions gracefully.
  # If a batch with the same ID is created by another thread
  # we fetch the batch that was created (rather than throwing
  # an error) and continute.
  def self.safe_create(id)
    batch = nil
    acquire_lock_for(id) do
      begin
        batch = Batch.create(id: id)
      rescue ActiveFedora::IllegalOperation
        batch = Batch.find(id)
      end
    end
    batch
  end

  private

    def self.acquire_lock_for(lock_key, &block)
      lock_manager.lock(lock_key, &block)
    end

    def self.lock_manager
      @lock_manager ||= Sufia::LockManager.new(
        Sufia.config.lock_time_to_live,
        Sufia.config.lock_retry_count,
        Sufia.config.lock_retry_delay)
    end
end

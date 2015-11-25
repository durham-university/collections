# This file is from Sufia pull request https://github.com/projecthydra/sufia/issues/1362
# Remove this when updating to a Sufia which already has this file. See the
# relevant local pull request for other files which were modified.

require 'redlock'
module Sufia
  class LockManager
    class UnableToAcquireLockError < StandardError; end

    # TODO: This file is the same as curation_concerns/curation_concerns-models/app/services/curation_concerns/lock_manager.rb.
    #       During the merge of Sufia to use Curation Concerns, this file may be replaced by the Curation Concerns version.

    attr_reader :client

    # @param [Fixnum] time_to_live How long to hold the lock in milliseconds
    # @param [Fixnum] retry_count How many times to retry to acquire the lock before raising UnableToAcquireLockError
    # @param [Fixnum] retry_delay Maximum wait time in milliseconds before retrying. Wait time is a random value between 0 and retry_delay.
    def initialize(time_to_live, retry_count, retry_delay)
      @ttl = time_to_live
      @client = Redlock::Client.new([uri], retry_count: retry_count, retry_delay: retry_delay)
    end

    # Blocks until lock is acquired or timeout.
    def lock(key)
      client.lock(key, @ttl) do |locked|
        if locked
          yield
        else
          raise UnableToAcquireLockError
        end
      end
    end

    private

      def uri
        @uri ||= begin
          opts = options
          URI("#{opts[:scheme]}://#{opts[:host]}:#{opts[:port]}").to_s
        end
      end

      def options
        ::Resque.redis.redis.client.options
      end
  end
end

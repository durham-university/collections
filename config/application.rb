require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Sufia
  class Application < Rails::Application

    config.to_prepare do
      # == APPLY MONKEY PATCHES ==

      # to_prepare gets executed when reloading classes so that development
      # environment re-applies the patches when classes are reloaded. In
      # production this should only get executed once.

      # Prepend adds the definitions after already existing ones and overrides
      # them. Include adds the definitions before those in the class.
      SimpleForm::Inputs::Base.class_eval do
        include SimpleFormsInputBasePatch # in app/inputs/simple_forms_input_base_patch.rb
      end
      MultiValueInput.class_eval do
        prepend MultiValueInputPatch # in app/inputs/multi_value_input_patch.rb
      end
      BatchUpdateJob.class_eval do
        prepend BatchUpdateJobPatch # in app/jobs/batch_update_job_patch.rb
      end
      Sufia::GenericFile::Actor.class_eval do
        prepend GenericFileActorPatch # in app/actors/generic_file_actor_patch.rb
      end
    end

    config.generators do |g|
      g.test_framework :rspec, :spec => true
    end

    config.autoload_paths += Dir["#{config.root}/lib/**/"]
    config.autoload_paths += Dir["#{config.root}/app/jobs"]

    # This is only needed for the temporary batch locking patch.
    # See comments in app/services/sufia/lock_manager.rb
    config.autoload_paths += Dir["#{config.root}/app/services"]

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true
  end
end

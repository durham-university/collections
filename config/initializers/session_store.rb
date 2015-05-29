# Be sure to restart your server when you modify this file.

config = YAML::load(ERB.new(IO.read(File.join(Rails.root, 'config', 'redis_session.yml'))).result)[Rails.env].with_indifferent_access

Rails.application.config.session_store :redis_session_store, {
  key: '_sufia_session',
  redis: {
    db: config[:db] || 1,
    expire_after: (config[:expire] || 120).minutes,
    key_prefix: config[:keyprefix] || 'sufia:session:',
    host: config[:host] || 'localhost',
    port: config[:port] || 6379
  }
}

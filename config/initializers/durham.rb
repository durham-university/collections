file = Rails.root.join('config/durham.yml').to_s
DURHAM_CONFIG = YAML.load(ERB.new(File.read(file)).tap do |erb| erb.filename = file end .result)[Rails.env]

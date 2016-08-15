module HydraFileCharacterizationToTempFilePatch
  # monkey patch to not read file contents in memory
  # Patch applied in config/application.rb
  
  def call(data)
    f = Tempfile.new([File.basename(filename),File.extname(filename)])
    begin
      f.binmode
      if data.respond_to? :read
        IO.copy_stream(data, f)
      else
        f.write(data)
      end
      f.rewind
      yield(f)
    ensure
      data.rewind if data.respond_to? :rewind
      f.close
      f.unlink
    end
  end
end
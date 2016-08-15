module HydraDerivativesExtractMetadataPatch
  # Monkey patch to_tempfile not to read the entire file contents in memory.
  # Patch applied in config/application.rb
  
  def extract_metadata
    return unless has_content?
    Hydra::FileCharacterization.characterize(content_stream, filename_for_characterization.join(""), :fits) do |config|
      config[:fits] = Hydra::Derivatives.fits_path
    end
  end
  
  def content_stream
    FedoraStreamIO.new(self)
  end
  
  def to_tempfile(&block)
    return unless has_content?
    Tempfile.open(filename_for_characterization) do |f|
      f.binmode
      IO.copy_stream(content_stream, f)
      content.rewind if content.respond_to? :rewind
      f.rewind
      yield(f)
    end
  end
end
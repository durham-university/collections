# IO like object for reading Fedora files 

class FedoraStreamIO
  def initialize(fedora_file)
    @fedora_file = fedora_file
    @closed = false
    rewind
  end

  def size
    @fedora_file.size
  end

  def length
    size
  end

  def binmode
    # Do nothing.
    # Some code insists on calling binmode on readable objects.
  end

  def read(amount=nil, buf=nil)
    raise IOError, "stream closed" if @closed
    buf ||= ''
    buf.clear
    return buf if amount==0

    if amount.nil?
      buf << consume_buffer
      while chunk = @stream_fiber.resume
        buf << chunk
      end
    else
      buf << consume_buffer(amount)
      return buf if buf.length >= amount
      while chunk = @stream_fiber.resume
        if buf.length + chunk.length >= amount
          d = amount-buf.length
          buf << chunk[0..(d-1)]
          @buffer = chunk[d..-1]
          break
        else
          buf << chunk
        end
      end
    end
    return nil if buf.empty? && amount.present?
    return buf
  end

  def rewind
    raise IOError, "stream closed" if @closed
    @buffer = ''
    @stream_fiber = Fiber.new do
      @fedora_file.stream.each do |chunk|
        Fiber.yield chunk
      end
      Fiber.yield nil
    end
  end

  def close
    @closed = true
  end

  private

    def consume_buffer(count=nil)
      @buffer.slice!(0, count || @buffer.length)
    end
end
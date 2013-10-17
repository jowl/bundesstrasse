module ZMQ
  class ValuePointer
    def initialize(type, val=nil)
      @type = type
      @pointer = FFI::MemoryPointer.new(@type, 1, true)
      self.value = val if val
    end

    def size
      @size ||= @pointer.size
    end

    def size=(size)
      @size = size
    end

    def address
      @pointer
    end

    def value=(val)
      @pointer.send("write_#{@type}", val)
    end

    def value
      @pointer.send("read_#{@type}")
    end
  end

  class TimePointer < ValuePointer
    def initialize(val=nil)
      super(:int, val)
    end

    def value=(val)
      super(val >= 0 ? (val * 1000).round : -1)
    end

    def value
      val = super
      val >= 0 ? val.fdiv(1000) : -1
    end
  end

  class BooleanPointer < ValuePointer
    def initialize(val=nil)
      super(:int, val)
    end

    def value=(val)
      super(val ? 1 : 0)
    end

    def value
      super == 1
    end
  end

  class BytesPointer < ValuePointer
    def initialize(val=nil)
      @type = :bytes
      @pointer = FFI::MemoryPointer.new(val ? val.bytesize : 255, 1, true)
      self.value = val if val
    end

    def value
      return if size == 255 && @pointer.read_string.empty?
      @pointer.read_bytes(size).tap { |s| s.chomp!(NULL) }
    end

    NULL = "\0".freeze
  end
end

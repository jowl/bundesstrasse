require 'spec_helper'

module ZMQ
  describe ValuePointer do
    let :pointer do
      described_class.new(:int, 42)
    end

    describe '#size' do
      it 'returns the bytesize of the pointer' do
        pointer.size.should == 4
      end
    end

    describe '#address' do
      it 'returns the wrapped ffi pointer' do
        pointer.address.should be_a(FFI::MemoryPointer)
      end
    end

    describe '#value' do
      it 'returns the (ruby) value of the pointer' do
        pointer.value.should == 42
      end
    end

    describe '#value=' do
      it 'writes the value to the pointer' do
        pointer.value = 10
        pointer.value.should == 10
      end
    end
  end

  describe TimePointer do
    let :pointer do
      described_class.new
    end

    describe '#value=' do
      it 'turns fractional seconds into integral milliseconds' do
        pointer.value = 3.333
        pointer.address.read_int.should == 3333
      end

      it 'rounds to nearest millisecond' do
        pointer.value = 0.0055
        pointer.value.should == 0.006
      end

      it 'writes 0 to pointer' do
        pointer.value = 0
        pointer.value.should == 0
      end

      it 'writes -1 to pointer for negative values' do
        pointer.value = -22.2
        pointer.value.should == -1
      end
    end
  end

  describe BooleanPointer do
    let :pointer do
      described_class.new(true)
    end

    describe '#value' do
      it 'returns the boolean value of the pointer' do
        pointer.value.should be_true
      end
    end

    describe '#value=' do
      it 'writes the value to the pointer' do
        pointer.value = false
        pointer.value.should be_false
      end
    end
  end

  describe BytesPointer do
    let :value do
      'value'
    end

    let :pointer do
      described_class.new(value)
    end

    describe '#size' do
      it 'returns the bytesize of the pointer' do
        pointer.size.should == value.bytesize
      end
    end

    describe '#size=' do
      it 'is possible to manually adjust the size of the value' do
        pointer.size = 1
        pointer.value.should == value[0]
      end
    end

    describe '#address' do
      it 'returns the wrapped ffi pointer' do
        pointer.address.should be_a(FFI::MemoryPointer)
      end
    end

    describe '#value' do
      it 'returns the (ruby) value of the pointer' do
        pointer.value.should == value
      end

      it 'returns nil if nothing has been written to pointer' do
        pointer = described_class.new
        pointer.value.should == nil
      end

      it 'returns nil if only null-bytes have been written to pointer' do
        pointer = described_class.new
        pointer.value = "\0\0\0\0"
        pointer.value.should == nil
      end
    end

    describe '#value=' do
      it 'writes the value to the pointer' do
        pointer.value = 'other'
        pointer.value.should == 'other'
      end

      it 'raises IndexError if new value is longer than initial value' do
        expect { pointer.value = value + value }.to raise_error(IndexError)
      end
    end
  end
end


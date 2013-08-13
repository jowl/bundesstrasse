require 'spec_helper'

module Bundesstrasse
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
end

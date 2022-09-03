# frozen_string_literal: true

module Aws
  module Embedded
    module Metrics
      class Units
        # Time
        SECONDS = 'Seconds'
        MICROSECONDS = 'Microseconds'
        MILLISECONDS = 'Milliseconds'

        # Size
        BYTES = 'Bytes'
        KILOBYTES = 'Kilobytes'
        MEGABYTES = 'Megabytes'
        GIGABYTES = 'Gigabytes'
        TERABYTES = 'Terabytes'

        BITS = 'Bits'
        KILOBITS = 'Kilobits'
        MEGABITS = 'Megabits'
        GIGABITS = 'Gigabits'
        TERABITS = 'Terabits'

        # Simple units
        PERCENT = 'Percent'
        COUNT = 'Count'

        # Size over time
        BYTES_SECOND = "#{BYTES}/Second"
        KILOBYTES_SECOND = "#{KILOBYTES}/Second"
        MEGABYTES_SECOND = "#{MEGABYTES}/Second"
        GIGABYTES_SECOND = "#{GIGABYTES}/Second"
        TERABYTES_SECOND = "#{TERABYTES}/Second"

        BITS_SECOND = "#{BITS}/Second"
        KILOBITS_SECOND = "#{KILOBITS}/Second"
        MEGABITS_SECOND = "#{MEGABITS}/Second"
        GIGABITS_SECOND = "#{GIGABITS}/Second"
        TERABITS_SECOND = "#{TERABITS}/Second"

        COUNT_SECOND = "#{COUNT}/Second"

        # Unit-less
        NONE = 'None'
      end
    end
  end
end

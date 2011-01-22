module Adyen
  module Formatter
    module DateTime
      # Returns a valid Adyen string representation for a date
      def self.fmt_date(date)
        case date
        when Date, DateTime, Time
          date.strftime('%Y-%m-%d')
        else
          raise "Invalid date notation: #{date.inspect}!" unless /^\d{4}-\d{2}-\d{2}$/ =~ date
          date
        end
      end

      # Returns a valid Adyen string representation for a timestamp
      def self.fmt_time(time)
        case time
        when Date, DateTime, Time
          time.strftime('%Y-%m-%dT%H:%M:%SZ')
        else
          raise "Invalid timestamp notation: #{time.inspect}!" unless /^\d{4}-\d{2}-\d{2}T\d{2}\:\d{2}\:\d{2}Z$/ =~ time
          time
        end
      end
    end
  end
end
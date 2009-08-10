require "#{File.dirname(__FILE__)}/spec_helper.rb"

describe Adyen do
  describe Adyen::Encoding do
    it "should a hmac_base64 correcly" do
      encoded_str = Adyen::Encoding.hmac_base64('bla', 'bla')
      encoded_str.should_not be_blank
      encoded_str.size.should == 28
    end    
    
    it "should gzip_base64 correcly" do
      encoded_str = Adyen::Encoding.gzip_base64('bla')
      encoded_str.should_not be_blank
      encoded_str.size.should == 32
    end
  end

  describe Adyen::Formatter::DateTime do
    it "should accept dates" do
      Adyen::Formatter::DateTime.fmt_date(Date.today).should match(/^\d{4}-\d{2}-\d{2}$/)
    end
    
    it "should accept times" do
      Adyen::Formatter::DateTime.fmt_time(Time.now).should match(/^\d{4}-\d{2}-\d{2}T\d{2}\:\d{2}\:\d{2}Z$/)
    end
    
    it "should accept valid time strings" do
      Adyen::Formatter::DateTime.fmt_time('2009-01-01T11:11:11Z').should match(/^\d{4}-\d{2}-\d{2}T\d{2}\:\d{2}\:\d{2}Z$/)
    end    
    
    it "should accept valid time strings" do    
      Adyen::Formatter::DateTime.fmt_date('2009-01-01').should match(/^\d{4}-\d{2}-\d{2}$/)
    end

    it "should raise on an invalid time string" do
      lambda { Adyen::Formatter::DateTime.fmt_time('2009-01-01 11:11:11') }.should raise_error
    end    

    it "should raise on an invalid date string" do
      lambda { Adyen::Formatter::DateTime.fmt_date('2009-1-1') }.should raise_error
    end    
  end

  describe Adyen::Formatter::Price do
    it "should return a Fixnum with digits only when converting to cents" do
      Adyen::Formatter::Price.in_cents(33.76).should be_kind_of(Fixnum)
    end

    it "should return a BigDecimal when converting from cents" do
      Adyen::Formatter::Price.from_cents(1234).should be_kind_of(BigDecimal)
    end
  end
end
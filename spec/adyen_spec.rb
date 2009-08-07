require "#{File.dirname(__FILE__)}/spec_helper.rb"

describe Adyen do

  describe 'dates en times' do
    it "should accept dates" do
      Adyen.date(Date.today).should match(/^\d{4}-\d{2}-\d{2}$/)
    end
    
    it "should accept times" do
      Adyen.time(Time.now).should match(/^\d{4}-\d{2}-\d{2}T\d{2}\:\d{2}\:\d{2}Z$/)
    end
    
    it "should accept valid time strings" do
      Adyen.time('2009-01-01T11:11:11Z').should match(/^\d{4}-\d{2}-\d{2}T\d{2}\:\d{2}\:\d{2}Z$/)
    end    
    
    it "should accept valid time strings" do    
      Adyen.date('2009-01-01').should match(/^\d{4}-\d{2}-\d{2}$/)
    end

    it "should raise on an invalid time string" do
      lambda { Adyen.time('2009-01-01 11:11:11') }.should raise_error
    end    

    it "should raise on an invalid date string" do
      lambda { Adyen.date('2009-1-1') }.should raise_error
    end    
  end

  describe Adyen::Price do

    it "should return a string with digits only when converting to cents" do
      Adyen::Price.in_cents(33.76).should match(/^\-?\d+/)
    end

    it "should return a BigDecimal when converting from cents" do
      Adyen::Price.from_cents(1234).should be_kind_of(BigDecimal)
    end
  end
end


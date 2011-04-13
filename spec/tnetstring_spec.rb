require 'spec_helper'

describe TNetstring do
  it "parses an integer" do
    TNetstring.parse('5:12345#').should == 12345
  end

  it "parses an empty string" do
    TNetstring.parse('0:,').should == ""
  end

  it "parses a string" do
    TNetstring.parse('12:this is cool,').should == "this is cool"
  end

  it "parses to an empty array" do
    TNetstring.parse('0:]').should == []
  end

  it "parses an arbitrary array of ints and strings" do
    TNetstring.parse('24:5:12345#5:67890#5:xxxxx,]').should == [12345, 67890, 'xxxxx']
  end

  it "parses to an empty hash" do
    TNetstring.parse('0:}').should == {}
  end

  it "parses an arbitrary hash of ints, strings, and arrays" do
    TNetstring.parse('34:5:hello,22:11:12345678901#4:this,]}').should == {"hello" => [12345678901, 'this']}
  end

  it "parses a null" do
    TNetstring.parse('0:~').should == nil
  end

  it "raises on a lengthy null" do
    expect { TNetstring.parse('1:x~') }.to raise_error
  end

  it "parses a boolean" do
    TNetstring.parse('4:true!').should == true
  end

  it "raises on a bad boolean" do
    expect { TNetstring.parse('5:pants!') }.to raise_error
  end

  it "raises with negative length" do
    expect { TNetstring.parse("-1:asd,") }.to raise_error
  end

  it "raises with absurd length" do
    expect { TNetstring.parse("1000000000:asd,") }.to raise_error
  end

  it "raises on unknown type" do
    expect { TNetstring.parse('0:)') }.to raise_error
  end
end
# -*- encoding: utf-8 -*-

require 'tnetstring'

describe TNetstring do
  describe "parsing" do
    describe "integers" do
      it "parses a positive integer" do
        TNetstring.parse('5:12345#')[0].should == 12345
      end

      it "parses a negative integer" do
        TNetstring.parse('6:-12345#')[0].should == -12345
      end
    end

    describe "floats" do
      it "parses a positve float" do
        TNetstring.parse('3:3.5^')[0].should == 3.5
      end

      it "parses a negative float" do
        TNetstring.parse('5:-3.14^')[0].should == -3.14
      end

      it "parses a float with leading zeros" do
        TNetstring.parse('7:-000.14^')[0].should == -0.14
      end
    end

    it "parses an empty string" do
      TNetstring.parse('0:,')[0].should == ""
    end

    it "parses a string" do
      TNetstring.parse('12:this is cool,')[0].should == "this is cool"
    end

    it "parses an empty array" do
      TNetstring.parse('0:]')[0].should == []
    end

    it "parses an arbitrary array of ints and strings" do
      TNetstring.parse('24:5:12345#5:67890#5:xxxxx,]')[0].should == [12345, 67890, 'xxxxx']
    end

    it "parses an empty hash" do
      TNetstring.parse('0:}')[0].should == {}
    end

    it "parses an arbitrary hash of ints, strings, and arrays" do
      TNetstring.parse('34:5:hello,22:11:12345678901#4:this,]}')[0].should == {"hello" => [12345678901, 'this']}
    end

    it "parses a null" do
      TNetstring.parse('0:~')[0].should == nil
    end

    it "parses a dictionary with a null value" do
      TNetstring.parse("9:3:key,0:~}")[0].should == {"key" => nil}
    end

    it "raises on a lengthy null" do
      lambda { TNetstring.parse('1:x~')[0] }.should.raise(TNetstring::ProcessError)
    end

    it "parses a boolean" do
      TNetstring.parse('4:true!')[0].should == true
    end

    it "raises on a bad boolean" do
      lambda { TNetstring.parse('5:pants!')[0] }.should.raise(TNetstring::ProcessError)
    end

    it "raises with negative length" do
      lambda { TNetstring.parse("-1:asd,")[0] }.should.raise(TNetstring::ProcessError)
    end

    it "raises with absurd length" do
      lambda { TNetstring.parse("1000000000:asd,")[0] }.should.raise(TNetstring::ProcessError)
    end

    it "raises on unknown type" do
      lambda { TNetstring.parse('0:)')[0] }.should.raise(TNetstring::ProcessError)
    end
  end

  #TODO: re-implement without rspec stubbing and reword to make it more clear
  #      that we're testing deprecation
  #
  # describe "encoding" do
  #   before { TNetstring.stub(:warn) }
  # 
  #   it "delegates to TNetstring.dump" do
  #     TNetstring.should_receive(:dump).with(nil).and_return("0:~")
  #     TNetstring.encode(nil).should == "0:~"
  #   end
  # 
  #   it "calls Kernel#warn" do
  #     TNetstring.should_receive(:warn)
  #     TNetstring.encode(nil)
  #   end
  # end

  describe "dumping" do
    describe "integers" do
      it "dumps a positive integer" do
        TNetstring.dump(42).should == "2:42#"
      end

      it "dumps a negative integer" do
        TNetstring.dump(-42).should == "3:-42#"
      end
      
      it "handles 32bit LONG_MAX" do
        TNetstring.dump(0x7fffffff).should == "10:2147483647#"
      end
      
      it "handles 64bit LONG_MAX" do
        TNetstring.dump(0x7fffffffffffffff).should == "19:9223372036854775807#"
      end
    end

    describe "floats" do
      it "dumps a positive float" do
        TNetstring.dump(12.3).should == "4:12.3^"
      end

      it "dumps a negative float" do
        TNetstring.dump(-2.3).should == "4:-2.3^"
      end

      it "dumps a float with integral value" do
        TNetstring.dump(-42.0).should == "5:-42.0^"
      end
    end

    it "dumps a string" do
      TNetstring.dump("hello world").should == "11:hello world,"
    end

    describe "boolean" do
      it "dumps true as 'true'" do
        TNetstring.dump(true).should == "4:true!"
      end

      it "dumps false as 'false'" do
        TNetstring.dump(false).should == "5:false!"
      end
    end

    it "dumps nil" do
      TNetstring.dump(nil).should == "0:~"
    end

    describe "arrays" do
      it "dumps an empty array" do
        TNetstring.dump([]).should == "0:]"
      end

      it "dumps an array of arbitrary elements" do
        TNetstring.dump(["cat", false, 123]).should == "20:3:cat,5:false!3:123#]"
      end

      it "dumps nested arrays" do
        TNetstring.dump(["cat", [false, 123]]).should == "24:3:cat,14:5:false!3:123#]]"
      end
    end

    describe "hashes" do
      it "dumps an empty hash" do
        TNetstring.dump({}).should == "0:}"
      end

      it "dumps an arbitrary hash of primitives and arrays" do
        TNetstring.dump({"hello" => [12345678901, 'this']}).should == '34:5:hello,22:11:12345678901#4:this,]}'
      end

      it "dumps nested hashes" do
        TNetstring.dump({"hello" => {"world" => 42}}).should == '25:5:hello,13:5:world,2:42#}}'
      end

      it "accepts symbols as keys" do
        TNetstring.dump({:hello => {"world" => 24}}).should == '25:5:hello,13:5:world,2:24#}}'
      end

      it "rejects non-String keys" do
        lambda { TNetstring.dump({123 => "456"}) }.should.raise(TNetstring::ProcessError)
      end
    end

    it "rejects non-primitives" do
      lambda { TNetstring.dump(Object.new) }.should.raise(TNetstring::ProcessError)
    end
  end
end

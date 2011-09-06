# -*- encoding: utf-8 -*-

require 'tnetstring'

describe TNetstring do
  
  # The loosely specified tagged netstring format conflicts with itself
  # slightly when it comes to UTF8. It's stated that the string type is
  # US-ASCII only, and that UTF8 is forbidden. Just below that is a
  # statement that anything that doesn't perfectly interoperate with the
  # reference implementation in python "is wrong and is not tnetstrings".
  # The reference implementation, however, supports UTF8 just fine. From
  # an ipython session pulling the example and evaluating it straight from
  # the site:
  #
  # In [1]: %loadpy http://tnetstrings.org/tnetstrings.py
  # In [3]: dump("π")
  # Out[3]: '2:\xcf\x80,'
  # In [4]: parse("2:π,")
  # Out[4]: ('\xcf\x80', '')
  #
  # Since it's in my own best interests to support UTF8 and I'm perfectly
  # OK with the idea that some random implementation might not, I'll weigh
  # the later statement as having greater authority. (^_-)b
  it "properly handles strings containing multibyte characters" do
    tasty_pi = "\xcf\x80"
    
    # chars.count and bytesize should be supported from 1.8.7+
    tasty_pi.chars.count.should == 1
    tasty_pi.bytesize.should == 2
    
    TNetstring.dump(tasty_pi).should == "2:#{tasty_pi},"
    TNetstring.parse("2:#{tasty_pi},").should == tasty_pi
  end
  
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
    
    it "parses an absurdly nested array" do
      str = '243:238:233:228:223:218:213:208:203:198:193:188:183:178:173:' \
            '168:163:158:153:148:143:138:133:128:123:118:113:108:103:99:95:' \
            '91:87:83:79:75:71:67:63:59:55:51:47:43:39:35:31:27:23:19:15:' \
            '11:hello-there,]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]' \
            ']]]]]]'
      TNetstring.parse(str)[0].should == [[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[
        [[[[[[[[[[[[[[[[["hello-there"]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]
        ]]]]]]]]]]]]]]
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

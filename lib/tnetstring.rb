# -*- encoding: utf-8 -*-

require 'tnetstring/version'
require 'tnetstring/errors'

module TNetstring
  
  # Converts a tagged netstring into the appropriate data structure
  #
  # @example
  #   TNetstring.parse('5:12345#')
  #   #=> [12345, '']
  # @example
  #   TNetstring.parse('11:hello world,abc123')
  #   #=> ['hello world', 'abc123']
  #
  # @raise [ProcessError]
  # @param [String] tnetstring a string argument prefixed with a valid tagged
  #   netstring
  # @return [Array] a tuple of the parsed object and any remaining string
  #   input.
  def self.parse(tnetstring)
    payload, payload_type, remain = parse_payload(tnetstring)
    value = case payload_type
    when '#'
      payload.to_i
    when '^'
      payload.to_f
    when ','
      payload
    when ']'
      parse_list(payload)
    when '}'
      parse_dictionary(payload)
    when '~'
      assert payload.length == 0, "Payload must be 0 length for null"
      nil
    when '!'
      parse_boolean(payload)
    else
      assert false, "Invalid payload type: #{payload_type}"
    end
    [value, remain]
  end

  # @api private
  def self.parse_payload(data)
    assert data, "Invalid data to parse; it's empty"
    length, extra = data.split(':', 2)
    length = length.to_i
    assert length <= 999_999_999, "Data is longer than the specification allows"
    assert length >= 0, "Data length cannot be negative"

    payload, extra = extra[0, length], extra[length..-1]
    assert extra, "No payload type: #{payload}, #{extra}"
    payload_type, remain = extra[0,1], extra[1..-1]

    assert payload.length == length, "Data is wrong length: #{length} expected but was #{payload.length}"
    [payload, payload_type, remain]
  end

  # @api private
  def self.parse_list(data)
    return [] if data.length == 0
    list = []
    value, remain = parse(data)
    list << value

    while remain.length > 0
      value, remain = parse(remain)
      list << value
    end
    list
  end

  # @api private
  def self.parse_dictionary(data)
    return {} if data.length == 0

    key, value, extra = parse_pair(data)
    result = {key => value}

    while extra.length > 0
        key, value, extra = parse_pair(extra)
        result[key] = value
    end
    result
  end

  # @api private
  def self.parse_pair(data)
    key, extra = parse(data)
    assert key.kind_of?(String) || key.kind_of?(Symbol), "Dictionary keys must be Strings or Symbols"
    assert extra, "Unbalanced dictionary store"
    value, extra = parse(extra)

    [key, value, extra]
  end

  # @api private
  def self.parse_boolean(data)
    case data
    when "false"
      false
    when "true"
      true
    else
      assert false, "Boolean wasn't 'true' or 'false'"
    end
  end
  
  # Constructs a tagged netstring for a given object
  #
  # @deprecated Please use {TNetstring.dump} instead.
  # @param (see TNetstring.dump)
  # @return (see TNetstring.dump)
  def self.encode(obj)
    warn "[DEPRECATION] `encode` is deprecated.  Please use `dump` instead."
    dump obj
  end

  # Constructs a tagged netstring for a given object
  #
  # @note hash keys must be symbols or strings
  #
  # @example
  #   TNetstring.dump(12345)
  #   #=> '5:12345#'
  # @example
  #   TNetstring.dump({'hello' => 'world'})
  #   #=> '16:5:hello,5:world,}'
  #
  # @raise [ProcessError]
  # @param [String, Numeric, Boolean, Nil, Array, Hash] object
  # @return [String] tagged netstring
  def self.dump(obj)
    if obj.kind_of?(Integer)
      int_str = obj.to_s
      "#{int_str.length}:#{int_str}#"
    elsif obj.kind_of?(Float)
      float_str = obj.to_s
      "#{float_str.length}:#{float_str}^"
    elsif obj.kind_of?(String) || obj.kind_of?(Symbol)
      "#{obj.length}:#{obj},"
    elsif obj.is_a?(TrueClass)
      "4:true!"
    elsif obj.is_a?(FalseClass)
      "5:false!"
    elsif obj == nil
      "0:~"
    elsif obj.kind_of?(Array)
      dump_list(obj)
    elsif obj.kind_of?(Hash)
      dump_dictionary(obj)
    else
      assert false, "Object must be of a primitive type: #{obj.inspect}"
    end
  end

  # @api private
  def self.dump_list(list)
    contents = list.map {|item| dump(item)}.join
    "#{contents.length}:#{contents}]"
  end

  # @api private
  def self.dump_dictionary(dict)
    contents = dict.map do |key, value|
      assert key.kind_of?(String) || key.kind_of?(Symbol), "Dictionary keys must be Strings or Symbols"
      "#{dump(key)}#{dump(value)}"
    end.join
    "#{contents.length}:#{contents}}"
  end

  # @api private
  def self.assert(truthy, message)
    raise ProcessError.new(message) unless truthy
  end
end

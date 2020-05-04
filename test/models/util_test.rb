require 'test_helper'
class UtilTest < ActiveSupport::TestCase

  test 'eval to bool' do
    # Eval to true
    assert Util.eval_to_bool('hello')
    assert Util.eval_to_bool('true')
    assert Util.eval_to_bool('t')
    assert Util.eval_to_bool(1)
    assert Util.eval_to_bool(true)

    # Eval to false
    assert_not Util.eval_to_bool('false')
    assert_not Util.eval_to_bool('f')
    assert_not Util.eval_to_bool(0)
    assert_not Util.eval_to_bool(nil)
    assert_not Util.eval_to_bool(false)
  end

  test 'is json valid?' do
    # Hash is always valid (already jsonable format)
    assert Util.is_json_valid?({})
    assert Util.is_json_valid?({ valid: 'json' })

    # Valid JSON strings are valid
    assert Util.is_json_valid?("{}")
    assert Util.is_json_valid?("{\"valid\":\"json\"}")
    assert Util.is_json_valid?("{\"array_field\": [1, 2, 3], \"sub_hash\": {\"foo\":\"bar\"} }")

    # Misc. invalid inputs
    assert_not Util.is_json_valid?(nil)
    assert_not Util.is_json_valid?("")
    assert_not Util.is_json_valid?("sfjsfklsdflkjdf")
    assert_not Util.is_json_valid?("[1, 2, 3, 4, 5]") # invalid because we cannot make a hash out of it
  end

  test 'is iso timestamp?' do
    # Valid dates
    assert Util.is_iso_timestamp?("2000-12-31T23:39:21Z")
    assert Util.is_iso_timestamp?("2050-05-02T17:40:11+0000")
    assert Util.is_iso_timestamp?("2018-08-18T23:39:21.60Z")

    assert_not Util.is_iso_timestamp?("2020-05-02"), 'Date is not a timestamp'
    assert_not Util.is_iso_timestamp?("asdfuiaidfgushf"), 'Gibberish is not a timestamp'
    assert_not Util.is_iso_timestamp?("2020-13-02T23:39:21Z"), 'Date with invalid month should not be allowed'
  end

  test 'is date?' do
    # Valid dates - full timestamps also qualify as dates
    assert Util.is_date?("2000-05-02")
    assert Util.is_date?("2020-12-31")
    assert Util.is_date?("2000-05-02T23:39:21Z")
    assert Util.is_date?("2050-05-02T17:40:11+0000")
    assert Util.is_date?("2012-09-23T23:39:21.60Z")

    # Invalid dates
    assert_not Util.is_date?("asdfuiaidfgushf"), 'Gibberish is not a timestamp'
    assert_not Util.is_date?("2020-13-02T23:39:21Z"), 'Date with invalid month should not be allowed'
    assert_not Util.is_date?("05/02/2020"), 'Invalid format should not return a date (date is correct, format is not'
    assert_not Util.is_date?("2000-5-2"), 'Leading 0s are missing, should not parse'
  end
end
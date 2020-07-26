require 'test_helper'
class GasAutoFormatterTest < ActiveSupport::TestCase
  FORMAT_OPTIONS_DEFAULT = { GasFormatType::AUTO_DATE_FORMAT => true, GasFormatType::USE_HEADER_UNDERSCORES => true}

  test 'format - general' do
    # Failure cases - return input data
    assert_equal "blah", GasAutoFormatter.format("blah", {})
    assert_equal "foobar", GasAutoFormatter.format("foobar", FORMAT_OPTIONS_DEFAULT)

    # General success cases
    assert_equal "{\"foo\":\"bar\"}",
                 GasAutoFormatter.format("{\"foo\":\"bar\"}", FORMAT_OPTIONS_DEFAULT),
                 'Non date fields should not be changed'
    assert_equal "{\"foo\":{\"year\":2020,\"month\":5,\"day\":2}}",
                 GasAutoFormatter.format("{\"foo\":\"2020-05-02\"}", FORMAT_OPTIONS_DEFAULT),
                 'Format should change date format with auto date format on'
    assert_equal "{\"foo\":\"2020-05-02\"}",
                 GasAutoFormatter.format("{\"foo\":\"2020-05-02\"}", { GasFormatType::AUTO_DATE_FORMAT => false }),
                 'Format should not change dates with auto_date_format off'
  end

  test 'format calls format dates' do
    format_dates_mock = MiniTest::Mock.new
    format_dates_mock.expect :call, {}, [{ "foo" => "bar" }, FORMAT_OPTIONS_DEFAULT]

    GasAutoFormatter.stub :format_dates, format_dates_mock do
      GasAutoFormatter.format("{\"foo\":\"bar\"}", FORMAT_OPTIONS_DEFAULT)
    end

    assert_mock format_dates_mock
  end

  test 'format dates handles mixed dates' do
    mixed_body = {
        not_a_timestamp_string: "foobar",
        not_a_timestamp_array: [1, 2, 3],
        not_a_timestamp_int: 2000,
        not_a_timestamp_obj: { foo: "bar" },
        timestamp_date: "2018-08-18",
        timestamp_with_nanos: "2020-05-02T23:39:21.560Z"
    }

    result = GasAutoFormatter.format_dates(mixed_body, FORMAT_OPTIONS_DEFAULT)

    # No changes expected
    assert_equal mixed_body[:not_a_timestamp_string], result[:not_a_timestamp_string]
    assert_equal mixed_body[:not_a_timestamp_array], result[:not_a_timestamp_array]
    assert_equal mixed_body[:not_a_timestamp_int], result[:not_a_timestamp_int]
    assert_equal mixed_body[:not_a_timestamp_obj], result[:not_a_timestamp_obj]

    # Changes expected to the dates
    assert_not_equal mixed_body[:timestamp_date], result[:timestamp_date]
    expected_date = { "year": 2018, "month": 8, "day": 18 }
    assert_equal expected_date, result[:timestamp_date]
    assert_not_equal mixed_body[:timestamp_with_nanos], result[:timestamp_with_nanos]
    expected_timestamp = { "seconds": 1588462761, "nanos": 560000000 }
    assert_equal expected_timestamp, result[:timestamp_with_nanos]
  end

  test 'format dates handles dates' do
    body = {
        timestamp_date: "2018-08-18",
    }

    result = GasAutoFormatter.format_dates(body, FORMAT_OPTIONS_DEFAULT)

    expected_date = { "year": 2018, "month": 8, "day": 18 }
    assert_equal expected_date, result[:timestamp_date]
  end

  test 'format dates handles timestamps' do
    body = {
        timestamp_without_nanos: "2020-04-04T23:39:21Z",
        timestamp_with_offset: "2050-05-02T17:40:11+0000",
        timestamp_with_nanos: "2020-12-01T23:39:21.560Z"
    }

    result = GasAutoFormatter.format_dates(body, FORMAT_OPTIONS_DEFAULT)

    timestamp_without_nanos = { seconds: 1586043561, nanos: 0 }
    assert_equal timestamp_without_nanos, result[:timestamp_without_nanos]

    timestamp_with_offset = { seconds: 2535126011, nanos: 0 }
    assert_equal timestamp_with_offset, result[:timestamp_with_offset]

    timestamp_with_nanos = { seconds: 1606865961, nanos: 560000000 }
    assert_equal timestamp_with_nanos, result[:timestamp_with_nanos]
  end

  test 'format dates handles nested timestamps' do
    body = {
        top_level_ts: "2020-04-04T23:39:21Z",
        nested_ts: {
            timestamp_with_offset: "2050-05-02T17:40:11+0000",
            another_nested_ts: {
                timestamp_with_nanos: "2020-12-01T23:39:21.560Z"
            }
        }
    }

    result = GasAutoFormatter.format_dates(body, FORMAT_OPTIONS_DEFAULT)

    timestamp_without_nanos = { seconds: 1586043561, nanos: 0 }
    assert_equal timestamp_without_nanos, result[:top_level_ts]

    timestamp_with_offset = { seconds: 2535126011, nanos: 0 }
    assert_equal timestamp_with_offset, result[:nested_ts][:timestamp_with_offset]

    timestamp_with_nanos = { seconds: 1606865961, nanos: 560000000 }
    assert_equal timestamp_with_nanos, result[:nested_ts][:another_nested_ts][:timestamp_with_nanos]
  end

  # Check that with option we underscore
  # Without option we leave header AS IS
  test 'format header key' do
    # Safety cases
    assert_nil GasAutoFormatter.format_header_key(nil, {})
    assert_nil GasAutoFormatter.format_header_key("some", nil)
    assert_nil GasAutoFormatter.format_header_key(nil, nil)

    underscore_headers = { GasFormatType::USE_HEADER_UNDERSCORES => true}
    assert_equal "Random_header", GasAutoFormatter.format_header_key("Random-header", underscore_headers)
    assert_equal "OTHER_HEADER", GasAutoFormatter.format_header_key("OTHER-HEADER", underscore_headers)
    assert_equal "other_header", GasAutoFormatter.format_header_key("other-header", underscore_headers)

    no_underscore_headers = { GasFormatType::USE_HEADER_UNDERSCORES => false}
    assert_equal "Random-header", GasAutoFormatter.format_header_key("Random-header", no_underscore_headers)
    assert_equal "OTHER-HEADER", GasAutoFormatter.format_header_key("OTHER-HEADER", no_underscore_headers)
    assert_equal "other-header", GasAutoFormatter.format_header_key("other-header", no_underscore_headers)

    blank_headers = {}
    assert_equal "Random-header", GasAutoFormatter.format_header_key("Random-header", blank_headers)
    assert_equal "OTHER-HEADER", GasAutoFormatter.format_header_key("OTHER-HEADER", blank_headers)
    assert_equal "other-header", GasAutoFormatter.format_header_key("other-header", blank_headers)
  end

end
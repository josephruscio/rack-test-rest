require 'json'
require 'rack-test-rest/version'

module Rack
  module Test
    module Rest

      # defines expected resource-to-uri scheme. overload this in your class
      # if needed.
      #
      def resource_uri
        "#{@rack_test_rest[:root_uri]}/#{@rack_test_rest[:resource]}"
      end

      # create a new instance of the given resource, expecting a 201
      # unless the :code option is specified.
      #
      def create_resource(params={})
        expected_code, params = _rtr_prepare_params(params, no_id: true)

        puts "Posting to: '#{resource_uri}#{@rack_test_rest[:extension]}'" if @rack_test_rest[:debug]
        post "#{resource_uri}#{@rack_test_rest[:extension]}", params

        with_clean_backtraces do

          return handle_error_code(expected_code) if expected_code

          if @rack_test_rest[:debug]
            puts "#{last_response.status}: #{last_response.body}"
            puts last_response.original_headers["Location"]
          end

          assert_status_code(201)
          assert_content_type_is_json

          if @rack_test_rest[:location]
            assert last_response.original_headers["Location"] =~ @rack_test_rest[:location],
              "Response location header '%s' does not match RegExp '%s'" %
              [last_response.original_headers["Location"], @rack_test_rest[:location]]
          end

        end

        last_response.original_headers["Location"]
      end

      # create resource, but expect a 400 - helper for the common case
      # of testing invalid parameters for creating your resource.
      #
      def create_resource_invalid(opts)
        create_resource({code: 400}.merge(opts))
      end

      def read_resource(params={})
        id, expected_code, params = _rtr_prepare_params(params)

        if id
          uri = "#{resource_uri}/#{id}#{@rack_test_rest[:extension]}"
        else
          uri = "#{resource_uri}#{@rack_test_rest[:extension]}"
        end

        puts "GET #{uri} #{params.inspect}" if @rack_test_rest[:debug]
        get uri, params

        with_clean_backtraces do

          return handle_error_code(expected_code) if expected_code

          if @rack_test_rest[:debug]
            puts "Code: #{last_response.status}"
            puts "Body: #{last_response.body}"
          end

          assert_status_code(200)
          assert_content_type_is_json

        end

        JSON.parse(last_response.body)
      end

      def update_resource(params={})
        id, expected_code, params = _rtr_prepare_params(params)

        puts "Attempting to update #{id} with #{params.inspect}" if @rack_test_rest[:debug]

        put "#{resource_uri}/#{id}#{@rack_test_rest[:extension]}", params

        with_clean_backtraces do
          return handle_error_code(expected_code) if expected_code
          puts "#{last_response.status}: #{last_response.body}" if @rack_test_rest[:debug]
          assert_status_code(204)
        end
      end

      # update resource, but expect a 400 - helper for the common case
      # of testing invalid parameters for updating your resource.
      #
      def update_resource_invalid(opts)
        update_resource({code: 400}.merge(opts))
      end

      def delete_resource(params={})
        id, code, params = _rtr_prepare_params(params)
        delete "#{resource_uri}/#{id}#{@rack_test_rest[:extension]}", params

        with_clean_backtraces do
          return handle_error_code(code) if code
          assert_status_code(204)
        end
      end

      # Create a set number of the resource and test pagination up
      # to that number.
      #
      def paginate_resource(opts={})
        count       = opts.fetch(:count, 512)
        do_create   = opts.fetch(:do_create, true)
        max         = opts.fetch(:max_length, 100)
        read_params = opts.fetch(:read_params, {})
        start_count = opts.fetch(:existing_resource_count, 0)

        #populate the DB
        0.upto(count - 1) do |id|
          if do_create
            create_resource(yield(id))
          else
            yield(id)
          end
        end

        total = count + start_count
        retrieved = 0
        offset = 0

        while retrieved < total
          # Get a random number from 1-100
          length = rand(max - 1) + 1

          expected_length = (length > (total - retrieved)) ? (total - retrieved) : length

          if @rack_test_rest[:debug]
            puts "Requesting offset='#{offset}', length='#{length}'"
            puts "Expecting '#{expected_length}'"
          end

          get_params = read_params.merge(offset: offset, length: length)
          pg_resp = read_resource(get_params)

          with_clean_backtraces do
            puts "Received #{pg_resp[@rack_test_rest[:resource]].count} records" if @rack_test_rest[:debug]
            assert_equal(expected_length, pg_resp[@rack_test_rest[:resource]].count)

            puts "Found #{pg_resp["query"]["found"]} records" if @rack_test_rest[:debug]
            assert_equal(total, pg_resp["query"]["found"])

            assert_equal(total, pg_resp["query"]["total"])
            assert_equal(expected_length, pg_resp["query"]["length"])
            assert_equal(offset, pg_resp["query"]["offset"])

            retrieved += expected_length
            offset = retrieved
          end
        end
      end

    private

      # split out common arguments & protect payload to ensure
      # we don't modify it by reference
      def _rtr_prepare_params(params, opts={})
        # symbolize all keys & ensure we don't affect original object
        prep = params.each_with_object({}) { |(k,v),memo| memo[k.to_sym] = v }
        result = []
        result << prep.delete(:id) unless opts[:no_id]
        result << prep.delete(:code)
        result << prep
        result
      end

      def assert_content_type_is_json(response=last_response)
        # ignore character sets when evaluating content type
        content_type = response.headers['Content-Type'].split(';')[0].strip.downcase
        assert_equal 'application/json', content_type, 'Expected content type to be json'
      end

      def assert_status_code(code, response=last_response)
        assert_equal code, response.status,
          "Expected status #{code}, but got a #{last_response.status}.\nBody: #{last_response.body.empty? ? "empty" : last_response.body.inspect.chomp}"
      end

      def handle_error_code(code)
        assert_status_code(code)

        if @rack_test_rest[:debug]
          puts "Status: #{last_response.status}"
          puts "Headers:"
          puts last_response.headers.inspect
          puts "Body: #{last_response.body}"
        end
        assert_content_type_is_json

        if last_response.headers['Content-Length'].to_i > 0
          JSON.parse(last_response.body)
        else
          nil
        end
      end

      # remove library lines from call stack so error is reported
      # where the call to rack-test-rest is being made
      def with_clean_backtraces
        yield
      rescue MiniTest::Assertion => error
        cleaned = error.backtrace.reject do |line|
          line.index(/rack-test-rest[-.0-9]{0,}\/lib/)
        end
        error.set_backtrace(cleaned)
        raise
      end

    end
  end
end

module Rack
  module Test
    module Rest

      def resource_uri
        "#{@rack_test_rest[:root_uri]}/#{@rack_test_rest[:resource]}"
      end

      def handle_error_code(code)
        assert_status_code(code)

        if @rack_test_rest[:debug]
          puts "Status: #{last_response.status}" if @rack_test_rest[:debug]
          puts "Headers:"
          puts last_response.headers.inspect
          puts "Body: #{last_response.body}" if @rack_test_rest[:debug]
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
        cleaned = error.backtrace.reject {|l| l.index('rack-test-rest/lib')}
        error.set_backtrace(cleaned)
        raise
      end

      def create_resource(params={})
        expected_code = params[:code]
        params.delete :code

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
            assert last_response.original_headers["Location"] =~ @rack_test_rest[:location]
          end

        end

        last_response.original_headers["Location"]
      end

      def read_resource(params={})
        expected_code = params[:code]
        params.delete :code

        if params[:id]
          id = params[:id]
          params.delete(:id)
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
        expected_code = params[:code]
        params.delete :code

        id = params[:id]
        params.delete(:id)

        puts "Attempting to update #{id} with #{params.inspect}" if @rack_test_rest[:debug]

        put "#{resource_uri}/#{id}#{@rack_test_rest[:extension]}", params

        with_clean_backtraces do
          return handle_error_code(expected_code) if expected_code
          puts "#{last_response.status}: #{last_response.body}" if @rack_test_rest[:debug]
          assert_status_code(204)
        end
      end

      def delete_resource(params={})
        delete "#{resource_uri}/#{params[:id]}#{@rack_test_rest[:extension]}"

        with_clean_backtraces do
          return handle_error_code(params[:code]) if params[:code]
          assert_status_code(204)
        end
      end

      def paginate_resource(params={})

        count = params[:count] ? params[:count] : 512
        max = params[:max_length] ? params[:max_length] : 100

        #populate the DB
        0.upto(count - 1) do |id|
          if params.has_key?(:do_create) && params[:do_create] == false
            yield(id)
          else
            create_resource(yield(id))
          end
        end

        retrieved = 0
        offset = 0

        while retrieved < count
          # Get a random number from 1-100
          length = rand(max - 1) + 1

          expected_length = (length > (count - retrieved)) ? (count - retrieved) : length

          if @rack_test_rest[:debug]
            puts "Requesting offset='#{offset}', length='#{length}'"
            puts "Expecting '#{expected_length}'"
          end

          pg_resp = read_resource(:offset => offset, :length => length)

          with_clean_backtraces do
            puts "Received #{pg_resp[@rack_test_rest[:resource]].count} records" if @rack_test_rest[:debug]
            assert_equal(expected_length, pg_resp[@rack_test_rest[:resource]].count)

            puts "Found #{pg_resp["query"]["found"]} records" if @rack_test_rest[:debug]
            assert_equal(count, pg_resp["query"]["found"])

            assert_equal(count, pg_resp["query"]["total"])
            assert_equal(expected_length, pg_resp["query"]["length"])
            assert_equal(offset, pg_resp["query"]["offset"])

            retrieved += expected_length
            offset = retrieved
          end
        end
      end

    private

      def assert_content_type_is_json(response=last_response)
        # ignore character sets when evaluating content type
        content_type = response.headers['Content-Type'].split(';')[0].strip.downcase
        assert_equal 'application/json', content_type, 'Expected content type to be json'
      end

      def assert_status_code(code, response=last_response)
        assert_equal code, response.status,
          "Expected status #{code}, but got a #{last_response.status}.\nBody: #{last_response.body.empty? ? "empty" : last_response.body.inspect.chomp}"
      end

    end
  end
end

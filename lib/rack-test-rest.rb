require 'pp'

module Rack
  module Test
    module Rest

      def resource_uri
        "#{@rack_test_rest[:root_uri]}/#{@rack_test_rest[:resource]}"
      end

      def handle_error_code(code)
        assert_equal code, last_response.status,
          "Expected #{code}, got #{last_response.status} - body #{last_response.body.empty? ? "empty" : last_response.body.pretty_inspect.chomp}"

        if @rack_test_rest[:debug]
          puts "Status: #{last_response.status}" if @rack_test_rest[:debug]
          puts "Headers:"
          puts last_response.headers.inspect
          puts "Body: #{last_response.body}" if @rack_test_rest[:debug]
        end
        assert_content_type_is_json(last_response)

        if last_response.headers['Content-Length'].to_i > 0
          JSON.parse(last_response.body)
        else
          nil
        end
      end

      def create_resource(params={})
        expected_code = params[:code]
        params.delete :code

        puts "Posting to: '#{resource_uri}#{@rack_test_rest[:extension]}'" if @rack_test_rest[:debug]
        post "#{resource_uri}#{@rack_test_rest[:extension]}", params

        return handle_error_code(expected_code) if expected_code

        if @rack_test_rest[:debug]
          puts "#{last_response.status}: #{last_response.body}"
          puts last_response.original_headers["Location"]
        end

        assert_equal(201, last_response.status)
        assert_content_type_is_json(last_response)

        if @rack_test_rest[:location]
          assert last_response.original_headers["Location"] =~ @rack_test_rest[:location]
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

        puts "GET #{uri} #{params.pretty_inspect}" if @rack_test_rest[:debug]
        get uri, params

        return handle_error_code(expected_code) if expected_code

        if @rack_test_rest[:debug]
          puts "Code: #{last_response.status}"
          puts "Body: #{last_response.body}"
        end

        assert_content_type_is_json(last_response)
        assert_equal(200, last_response.status)

        JSON.parse(last_response.body)
      end

      def update_resource(params={})
        expected_code = params[:code]
        params.delete :code

        id = params[:id]
        params.delete(:id)

        puts "Attempting to update #{id} with #{params.pretty_inspect}" if @rack_test_rest[:debug]

        put "#{resource_uri}/#{id}#{@rack_test_rest[:extension]}", params

        return handle_error_code(expected_code) if expected_code

        puts "#{last_response.status}: #{last_response.body}" if @rack_test_rest[:debug]

        assert_equal(204, last_response.status)
      end

      def delete_resource(params={})
        delete "#{resource_uri}/#{params[:id]}#{@rack_test_rest[:extension]}"

        return handle_error_code(params[:code]) if params[:code]

        assert_equal(204, last_response.status)
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

    private

      def assert_content_type_is_json(response)
        # ignore character sets when evaluating content type
        content_type = response.headers['Content-Type'].split(';')[0].strip.downcase
        assert_equal 'application/json', content_type
      end

    end
  end
end

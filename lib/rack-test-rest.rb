module Rack
  module Test
    module Rest

      def resource_uri
	"#{@rack_test_rest[:root_uri]}/#{@rack_test_rest[:resource]}"
      end

      def create_resource(params={})
        expected_code = params[:code]
        params.delete :code

        puts "Posting to: '#{resource_uri}.json'" if @rack_test_rest[:debug]
        post "#{resource_uri}.json", params

        if expected_code
          assert last_response.status == expected_code
        else
	  if @rack_test_rest[:debug]
            puts "#{last_response.status}: #{last_response.body}"
            puts last_response.original_headers["Location"]
	  end
          assert last_response.status == 201
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
	  uri = resource_uri + "/#{id}.json"
	else
	  uri = resource_uri + ".json"
	end

        puts "GET #{uri} #{params}" if @rack_test_rest[:debug]
        get uri, params

        if @rack_test_rest[:debug]
          puts "Code: #{last_response.status}"
          puts "Body: #{last_response.body}"
	end

        if expected_code
          assert last_response.status == expected_code
          return nil
        else
          assert last_response.status == 200
          return JSON.parse(last_response.body)
        end
      end

      def update_resource(params={})
        expected_code = params[:code]
        params.delete :code

        id = params[:id]
        params.delete(:id)

        puts "Attempting to update #{id} with #{params}" if @rack_test_rest[:debug]

        put "#{resource_uri}/#{id}.json", params

        puts "#{last_response.status}: #{last_response.body}" if @rack_test_rest[:debug]

        if expected_code
          assert last_response.status == expected_code
        else
          assert last_response.status == 204
        end
      end

      def delete_resource(params={})
        delete "#{resource_uri}/#{params[:id]}.json"

        if params[:code]
          assert last_response.status == params[:code]
        else
          assert last_response.status == 204
        end
      end

      def paginate_resource(params={})

        count = params[:count] ? params[:count] : 512
        max = params[:max_length] ? params[:max_length] : 100

        #populate the DB
        0.upto(count - 1) do |id|
          create_resource(yield(id))
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
          assert pg_resp[@rack_test_rest[:resource]].count == expected_length

          puts "Found #{pg_resp["query"]["found"]} records" if @rack_test_rest[:debug]
          assert pg_resp["query"]["found"] == count

          assert pg_resp["query"]["total"] == count
          assert pg_resp["query"]["length"] == expected_length
          assert pg_resp["query"]["offset"] == offset

          retrieved += expected_length
          offset = retrieved
        end
      end

    end
  end
end

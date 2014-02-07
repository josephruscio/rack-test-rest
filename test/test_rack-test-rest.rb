require 'test_helper'

class TestRackTestRest < Minitest::Test
  include Rack::Test::Methods
  include Rack::Test::Rest

  def app
    SampleApp
  end

  def setup
    @rack_test_rest = {
      #debug: true
      root_uri: '/v1',
      resource: 'users'
    }
  end

  def test_update_resource
    touched = Time.now
    update_resource(id: 12, email: 'user@test.com', touched_at: touched)

    # request
    assert last_request.put?
    assert_equal '/v1/users/12', last_request.path
    assert_equal 'user@test.com', last_request.params['email']
    assert_equal touched.to_s, last_request.params['touched_at']

    # response
    assert_equal 204, last_response.status
  end

end

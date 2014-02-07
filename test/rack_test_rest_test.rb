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

  def test_create_resource
    create_resource(email: 'fred@sinatra.com', password: 'groovy')

    # request
    assert last_request.post?
    assert_equal '/v1/users', last_request.path

    # response
    assert_equal 201, last_response.status
  end

  def test_read_resource
    read_resource(id: 15)

    # request
    assert last_request.get?
    assert_equal '/v1/users/15', last_request.path

    # response
    assert last_response.ok?
  end

  def test_read_should_not_modify_payload
    payload = {id: 21, foo: 'bar', boom: 'baz'}
    original = payload.dup

    read_resource(payload)
    assert_equal original, payload
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

  def test_update_should_not_modify_payload
    payload = {id: 21, foo: 'bar', boom: 'baz'}
    original = payload.dup

    update_resource(payload)
    assert_equal original, payload
  end

  def test_delete_resource
    delete_resource(id: 21)

    # request
    assert last_request.delete?
    assert_equal '/v1/users/21', last_request.path

    # response
    assert_equal 204, last_response.status
  end

  def test_delete_should_not_modify_payload
    payload = {id: 21, foo: 'bar', boom: 'baz'}
    original = payload.dup

    delete_resource(payload)
    assert_equal original, payload
  end

  def test_should_accept_string_params
    # param parsing is DRYed up now, so testing one route
    # should be adequate

    update_resource('id' => 34, 'email' => 'fred@idk.com')

    # request
    assert last_request.put?
    assert_equal '/v1/users/34', last_request.path
    assert_equal 'fred@idk.com', last_request.params['email']

    # response
    assert_equal 204, last_response.status
  end

end

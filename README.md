[![Gem Version](https://badge.fury.io/rb/rack-test-rest.png)](http://badge.fury.io/rb/rack-test-rest)

`rack-test-rest` is an extension to `rack-test` that when combined with
`Test::Unit` simplifies the process of unit testing properly
designed RESTful API's.

# Installation
    $ gem install rack-test-rest

# Use

`rack-test-rest` extends `rack-test` with a set of higher-level methods that
perform _CRUD_ operations against resources through a RESTful API that conforms
to best practices and validates that they respond correctly.
It's designed to be mixed into a subclass of `Test::Unit::Testcase`
that is testing a specific resource e.g.:

      class GaugeTest < Test::Unit::TestCase
        include Rack::Test::Methods
        include Rack::Test::Rest

        def setup
          @rack_test_rest = {
            #:debug => true,
            :root_uri => "/v1/metrics",
            :resource => "gauges",
            :extension => ".json" #other possibilities ".xml", "_json",".html", etc
          }
        end

        def test_create
          create_resource(:name => "foo")
          create_resource(:code => 422, :name => "foo")
        end

        def test_read
          create_resource(:name => "foo")

          gauge = read_resource(:id => "foo")
          assert gauge['name'] == "foo"
        end

        def test_update
          create_resource(:name => "foo", :description => "bar")

          update_resource(:id => "foo", :description => "baz")

          gauge = read_resource(:id => "foo")
          assert gauge['description'] == "baz"
        end

        def test_delete
          create_resource(:name => "foo")
          delete_resource(:id => "foo")
          read_resource(:code => 404, :id => "foo")
        end

`rack-test-rest` exploits _convention over configuration_ to minimize the amount of work
required to test any particular resource. You need only specify `:root_uri` and `:resource`
in your test setup (through the `@rack_test_rest` instance variable). These are combined
to create either the URI for creating/indexing resources or the URI for a particular resource:

    :root_uri + '/' + :resource + :extension
    :root_uri + '/' + :resource + '/' + params[:id].to_s + :extension

Currently JSON is the only supported response Content-Type.

## `create_resource(params={})`

Performs a POST to with any specified parameters to `:root_uri/:resource:extension`
and ensures that it returns `201`. Returns the string value found in the response's
`Location` header.

## `read_resource(params={})`

Performs a GET with any specified parameters and validates that it returns `200`.
If `:id` is specified the GET is performed against a singular resource i.e.
`:root_uri/:resource/:id:extension`. In the absence of `:id` the GET is performed
as an index operation against `:root_uri/:resource:extension`. Returns parsed
JSON of the response body on a `200`.

## `update_resource(params={})`

Requires an :id parameter. Performs a PUT against `:root_uri/:resource/:id:extension`
with any other specified parameters and asserts that it returns `204`.

## `delete_resource(params={})`

Requires an :id parameter. Performs a DELETE against `:root_uri/:resource/:id:extension`
and asserts that it returns `204`.

## Testing invalid input

Any of the CRUD operations can be altered to check that invalid input is properly
detected and returns the correct error code by specifying `:code` as a parameter
e.g.
    create_resource(:code => 422, :name => duplicate_name)
    read_resource(:code => 404, :id => invalid_id)

## Debugging
The point of unit tests is to surface and fix defects and/or regressions in your code
in the lab rather than than in production. When your tests fail you can include
`:debug => true` to instruct `rack-rest-test` to verbosely log to STDOUT the individual
HTTP requests it's performing and the results of each.

## Pagination
`rack-test-rest` also supports randomized tests for paginated resources assuming you follow
the [standard pagination scheme](http://dev.librato.com/v1/pagination). All you need supply it
with is a block it can use to generate unique parameters for populating the resources prior
to pagination tests. You can specify `:count` to control how many records are created and
paginated through (defaults to 512) and `:length` to specify the maximum number of resources
that a single index operation may return (defaults to 100).

    def test_gauge_pagination
      @db.run("DELETE FROM gauges")
      paginate_resource(){ |id| {:name => "foo_#{id}", :description => "gauge #{id}"} }
    end

# Contributions

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.
* Submit a pull request!

# Copyright

Copyright (c) 2011-2014 Joseph Ruscio. See LICENSE.txt for
further details.

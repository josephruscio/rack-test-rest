require 'sinatra/base'

module Rack::Test::Rest

  class SampleApp < Sinatra::Base

    get '/v1/users' do
      headers 'Content-Type' => 'application/json'
      body '{}'
    end

    post '/v1/users' do
      status 201
      headers 'Content-Type' => 'application/json'
      body '{}'
    end

    get '/v1/users/:id' do
      headers 'Content-Type' => 'application/json'
      body '{}'
    end

    put '/v1/users/:id' do
      status 204
    end

    delete '/v1/users/:id' do
      status 204
    end

  end

end
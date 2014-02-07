require 'sinatra/base'

module Rack::Test::Rest

  class SampleApp < Sinatra::Base

    get '/v1/users' do
    end

    post '/v1/users' do
    end

    put '/v1/users/:id' do
      status 204
    end

    delete '/v1/users/:id' do
      status 204
    end

  end

end
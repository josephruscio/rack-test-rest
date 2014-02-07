require 'rubygems'
require 'bundler/setup'
require 'pry'

require 'minitest/autorun'
require 'minitest/mock'

require 'rack'
require 'rack/test'
require 'rack-test-rest'

require File.dirname(__FILE__) + "/fixtures/sample_app"
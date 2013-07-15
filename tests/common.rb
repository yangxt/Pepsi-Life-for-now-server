 # -*- coding: utf-8 -*-
ENV['RACK_ENV'] = 'test'
require './app'
require 'test/unit'
require 'rack/test'
require 'json'
require './tests/test_tools'
require './helpers/constants'

ActiveRecord::Base.logger = nil
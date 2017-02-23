#!/usr/bin/env ruby
require 'sinatra'
require_relative './utils'
include ERB::Util

index = -> { erb :index }

get '/', &index
post '/', &index

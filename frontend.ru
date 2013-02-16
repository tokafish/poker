require 'rubygems'
require 'bundler'

Bundler.require

require "sinatra/base"

class Poker < Sinatra::Base
  set :server, 'thin'
  # set :redis, Redis.new(:url => "redis://localhost:6379/5")

  get '/' do
    haml :index
  end

  get '/cards/:card.html' do
    haml(:"cards/#{params[:card]}")
  end
end

require 'sass/plugin/rack'

Sass::Plugin.options[:template_location] = 'public/stylesheets'
use Sass::Plugin::Rack

use Rack::Coffee, root: 'public', urls: '/javascripts'

run Poker
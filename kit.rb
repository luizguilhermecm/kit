#!/usr/bin/env ruby
# encoding: UTF-8

require 'sinatra'
require 'sinatra/session'
require 'pg'
require './kit_config'

require_relative 'kit_todo'

class Kit < Sinatra::Base
  register Sinatra::Session
  set :bind, '0.0.0.0'
  set :port, 80 # to deploy on tcp port 80, sudo needed
  set :environment, :production
  set :host, DB_HOST
  set :dbname, DB_NAME
  set :user, DB_SYS_USER
  set :password, DB_SYS_PASSWD

  @@conn = PG.connect(:host => settings.host, :dbname => settings.dbname, :user => settings.user, :password => settings.password)

  enable :sessions

  set :session_fail, '/login'
  set :session_secret, 'whatThisMean?'

  configure :production do
    use Rack::Session::Pool
    set :erb, :trim => '-'
  end

  not_found do
    'Página não encontrada!'
  end

  get '/' do
      if session?
          redirect to('/todo')
      else
          erb :index
      end
  end

  get '/logout' do
      session_end!
      redirect to('/')
  end

  get '/login' do
      if session?
          redirect to('/todo')
      elsif params[:pass] == "snk"
          session_start!
          session[:user] = "snk"
          redirect to('/')
      else
          redirect to('/')
      end
  end

  run! if app_file == $0
end

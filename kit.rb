#!/usr/bin/env ruby
# encoding: UTF-8

require 'sinatra'
require 'sinatra/session'
require 'pg'

require_relative 'kit_todo'

class Kit < Sinatra::Base
  register Sinatra::Session
  set :bind, '0.0.0.0'
  set :environment, :production
  set :session_fail, '/login'
  set :session_secret, 'whatThisMean?'
  set :host, DB_HOST
  set :dbname, DB_NAME
  set :user, DB_SYS_USER
  set :password, DB_SYS_PASSWD

  @@conn = PG.connect(:host => settings.host, :dbname => settings.dbname, :user => settings.user, :password => settings.password)


  enable :sessions
  configure :production do
    use Rack::Session::Pool
    set :erb, :trim => '-'
  end

  not_found do
    'Página não encontrada!'
  end

  get '/' do
      if session?
          redirect '/main'
      else
          erb :index
      end
  end

  get '/logout' do
      session_end!
      'Fim'
  end

  get '/login' do
      if session?
          redirect '/todo'
      elsif params[:pass] == "snk"
          session_start!
          session[:user] = "snk"
          redirect '/'
      else
          redirect '/'
      end
  end

  run! if app_file == $0
end

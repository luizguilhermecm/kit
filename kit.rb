#!/usr/bin/env ruby
# encoding: UTF-8

require 'sinatra'
require 'sinatra/session'
require 'sinatra/base'
require 'rubygems'
require 'pg'
require 'json'
require 'digest/md5'
require "i18n"

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
      erb :error
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
      erb :index
  end

  post '/login' do
      if session?
          redirect to('/todo')
      else
        query = " SELECT id FROM users WHERE username = $1 AND passwd = $2 "
        ret = @@conn.exec_params(query, [params[:username], params[:passwd]])

        puts ret.first.to_s
        if ret.first
            session_start!
            session[:username] = params[:username]
            session[:uid] = ret.first["id"]
            redirect to('/')
        else

            session_start!

            log = "log_error: username: #{params[:username]} passwd: #{params[:passwd]} "
            log += " with IP: " + request.ip
            query = " INSERT INTO sys_log (log) VALUES ('#{log}') "
            @@conn.exec(query)

            session[:username] = params[:username]
            session[:uid] = 0

            redirect to('/')
            #erb :error , layout: false
        end
        #puts ret.first

      end
  end

  get '/git_pull' do
    session!
    if session[:uid] != 0
        `git pull`
        redirect to('/')
    end
  end

  get '/sinatra_log' do
    session!
    if session[:uid] != 0
        @output = IO.read('nohup.out')
        erb :log
    else
        redirect to('/')
    end
  end

  run! if app_file == $0
end

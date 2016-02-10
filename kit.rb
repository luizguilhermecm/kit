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
require_relative './kit_logging'

require_relative 'kit_todo'
require_relative 'kit_frase'
require_relative 'bijqc'
require_relative 'kit_admin'
require_relative 'kit_files'
#require_relative 'kit_daily'

class Kit < Sinatra::Base
    register Sinatra::Session
    set :bind, '0.0.0.0'
    set :port, 80 # to deploy on tcp port 80, sudo needed
    set :environment, :production
    set :host, DB_HOST
    set :dbname, DB_NAME_KIT
    set :db_wum, DB_NAME_WUM
    set :user, DB_SYS_USER
    set :password, DB_SYS_PASSWD

    #log_level = KIT_LOG_DEBUG
    #KIT_LOG_DEBUG = 48  # o mais verboso possivel
    #KIT_LOG_VERBOSE = 40
    #KIT_LOG_INFO = 32
    #KIT_LOG_ERROR = 16
    #KIT_LOG_PANIC = 0 # loga o mínimo possível

    #$logging_level = KIT_LOG_PANIC
    $logging_level = KIT_LOG_DEBUG

    @@wum_conn = PG.connect(:host => settings.host, :dbname => settings.db_wum, :user => settings.user, :password => settings.password)
    @@conn = PG.connect(:host => settings.host, :dbname => settings.dbname, :user => settings.user, :password => settings.password)

    enable :sessions

    set :session_fail, '/login'
    set :session_secret, 'whatThisMean?'

    set :dump_errors, false
    set :show_exceptions, :after_handler

    configure :production do
        use Rack::Session::Pool
        set :erb, :trim => '-'
    end

    not_found do
        kit_log(KIT_LOG_PANIC, "[ERROR-not-found]")
        erb :error
    end

    error do
        'Sorry there was a nasty error - ' + env['sinatra.error'].message
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
        puts "/login"
        if session?
            redirect to('/todo')
        else
            query = " SELECT id FROM users WHERE username = $1 AND passwd = $2 "
            begin
                ret = @@conn.exec_params(query, [params[:username], params[:passwd]])
            rescue => e
                puts "***************************"
                puts params[:username]
                puts params[:passwd]
                puts request.ip
                puts e
                puts "***************************"
                redirect to('/')
            end
            puts ret.first.to_s
            if ret.first
                session_start!
                puts "starting session"
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
            #@output = IO.read('nohup.out')
            @output = `tail -n 50 nohup.out`
            erb :log
        else
            redirect to('/')
        end
    end

    get '/sinatra_log/:filename' do |filename|
        session!
        send_file "./#{filename}", :filename => filename, :type => 'Application/octet-stream'
    end

    get '/set_log_level/:log_level' do |log_level|
        session!
        kit_log(KIT_LOG_PANIC, "new log level", log_level)
        $logging_level = log_level
        redirect to('/')
    end

    get '/kit_mae' do
        kit_log(KIT_LOG_PANIC, "kit_mae", request)
        query = "UPDATE kit_config SET value=value::int + 1, updated_at = now() WHERE property = 'MAE';"
        begin
            ret = @@conn.exec(query)
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR-kit-mae]", e, request)
            erb :kit_mae, layout: false
        end

  t = %w[text/css text/html application/javascript]
  print "  t "
puts  t
  print "  request.accept              "
puts  request.accept              # ['text/html', '*/*']
  print "  request.accept? text/xml  "
puts    request.accept? 'text/xml'  # true
  print "  request.preferred_type(t)   "
puts  request.preferred_type(t)   # 'text/html'
  print "  request.body                "
puts  request.body                # request body sent by the client (see below)
  print "  request.scheme              "
puts  request.scheme              # "http"
  print "  request.script_name         "
puts  request.script_name         # "/example"
  print "  request.path_info           "
puts  request.path_info           # "/foo"
  print "  request.port                "
puts  request.port                # 80
  print "  request.request_method      "
puts  request.request_method      # "GET"
  print "  request.query_string        "
puts  request.query_string        # ""
  print "  request.content_length      "
puts  request.content_length      # length of request.body
  print "  request.media_type          "
puts  request.media_type          # media type of request.body
  print "  request.host                "
puts  request.host                # "example.com"
  print "  request.get?                "
puts  request.get?                # true (similar methods for other verbs)
  print "  request.form_data?          "
puts  request.form_data?          # false
  print "  request.referrer            "
puts  request.referrer            # the referrer of the client or '/'
  print "  request.user_agent          "
puts  request.user_agent          # user agent (used by :agent condition)
  print "  request.cookies             "
puts  request.cookies             # hash of browser cookies
  print "  request.xhr?                "
puts  request.xhr?                # is this an ajax request?
  print "  request.url                 "
puts  request.url                 # "http://example.com/example/foo"
  print "  request.path                "
puts  request.path                # "/example/foo"
  print "  request.ip                  "
puts  request.ip                  # client IP address
  print "  request.secure?             "
puts  request.secure?             # false (would be true over ssl)
  print "  request.forwarded?          "
puts  request.forwarded?          # true (if running behind a reverse proxy)
  print "  request.env "
puts  request.env
        erb :kit_mae, layout: false
    end

    def logging e
        puts "***************************"
        puts session[:username]
        puts session[:uid]
        puts request.ip
        puts e
        puts "***************************"
    end

    run! if app_file == $0
end

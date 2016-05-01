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

require_relative 'kit_time'
require_relative 'kit_todo'
require_relative 'kit_frase'
require_relative 'bijqc'
require_relative 'kit_admin'
require_relative 'kit_files'
require_relative 'kit_daily'
require_relative 'kit_task_man'

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

    configure do

        set :raise_errors, true
        set :dump_errors, true
        set :show_exceptions, true

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

    before do
        if session[:kmsg]
            @kmsg = session[:kmsg]
            session[:kmsg] = nil
        end
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
        session_start!
        kit_log(KIT_LOG_INFO, "get /kit_mae", Time.now)
        query = " INSERT INTO kit_mae (text) VALUES ($1); ";

        kit_log(KIT_LOG_PANIC, "params", params)

        if params.first and params.first.at(1)
            text = params.first.at(1).to_s
        else
            text = 'keep_alive'
        end

        begin
            @@conn.exec_params(query, [text.to_s])
        rescue => e
            kit_log(KIT_LOG_ERROR, "[ERROR-kit-mae]", e, request)
            session_end!
            erb :kit_mae, layout: false
        end
        session_end!
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

    get '/contador' do
        erb :"ate/contador"
    end

    run! if app_file == $0
end

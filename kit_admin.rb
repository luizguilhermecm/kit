class Kit < Sinatra::Base

=begin
    feature: kit_admin

    goal:
        to have an admin page to do things that no one else can, like change
            log_level.

    tasks:
        + A new "class" to be responsible for the feature.
        + A table that will keep the data, such 'log_level' property and its
            actual value, and the property that will inform which user is admin.
            + this table will have at least these attributes:
                - id : serial primary key,
                - property : varchar : not null,
                - is_valid : boolean : default false,
                - is_unique : boolean : default false,
                - value : varchar : not null,
                - created_at : timestamp : default now(),
                - updated_at : timestamp : default now(),
                - description : varchar,
                * constraint unique(property, value) -- at this moment seens to
                    be necessary to avoid duplications and inconsistency.
                # business rules that affects the database:
                    - the attribute 'is_unique' will be used to classify those
                        properties thas must be "singleton", so it will be
                        created a trigger to ensure this rule.
                        The overview of trigger validation:
                            # It will be triggered on 'insert', 'update'.
                                If necessary on 'delete', a better analysis is
                                needed.
                            # The trigger will look into the table to ensure
                                that none of the 'property' is equal
                                'NEW.property'. If a 'property' that match the
                                rule, the 'NEW.property' will no be inserted or
                                updated on database.
                                Will be necessary an analysis to know if when
                                'OLD.property' is equal the attribute
                                'is_unique' will be considered to block the
                                operation?

    example:
        property = 'log_level'
        is_valid = true
        is_unique = true
        value = 'KIT_LOG_DEBUG'
        description = 'Define the level that kit will perform logging.'

        When a new insert is been performed is verified an existing property
        'log_level' with 'is_valid = true'.
            The trigger will refuse the insert?
            The trigger shoud update the existing one?

        When inserting the log_level, a check may be necessary to keep the
        values consistent.
=end

    get '/kit_admin' do
        session!
        get_kit_log_level
        get_distinct_log_level
        erb :kit_admin
    end

    def is_admin
        kit_log(KIT_LOG_INFO, '/is_admin', session[:uid], session[:username])
        session!

        query  = " SELECT 1 ";
        query += " WHERE EXISTS ";
        query += " (SELECT 1 ";
        query += " FROM kit_config ";
        query += " WHERE is_valid = TRUE ";
        query += " AND property = 'ADMIN_USER' ";
        query += " AND value = $1 ); ";

        begin
            kit_log(KIT_LOG_VERBOSE, query, session[:uid].to_s);
            ret = @@conn.exec_params(query, [session[:uid].to_s]);
            kit_log(KIT_LOG_VERBOSE, "ret.fields", ret.fields)
            kit_log(KIT_LOG_DEBUG, "ret.values", ret.values)
            if ret.first == nil
                kit_log(KIT_LOG_DEBUG, "The user is not admin, returning false");
                redirect to('/')
            else
                kit_log(KIT_LOG_DEBUG, "The user is admin, return true");
                return true;
            end
        rescue => e
            kit_log(KIT_LOG_PANIC, "[ERROR]", e, session)
            redirect to('/')
        end
    end

    get '/update_log_level' do
        kit_log(KIT_LOG_INFO, '/update_log_level')
        is_admin
        session!
        kit_log(KIT_LOG_INFO, "updating log level with value", params[:log_level].to_s);
        queryNew = "UPDATE kit_config SET is_valid = true WHERE property = 'LOG_LEVEL' AND value = $1 ;";
        query = " UPDATE kit_config SET is_valid = false WHERE property = 'LOG_LEVEL' AND is_valid = true ;";
        begin
            kit_log(KIT_LOG_DEBUG, "updates querys used", query, queryNew)
            ret = @@conn.exec(query);
            ret = @@conn.exec(queryNew, [params[:log_level]])
        rescue => e
            kit_log(KIT_LOG_PANIC, "[ERROR]", e, session)
            redirect to('/')
        end
        redirect to('/kit_admin')
    end


     get '/database_backup' do
         kit_log(KIT_LOG_INFO, '/database_backup')
        is_admin
        session!

        cmd = "kitbkp"

        begin
            kit_log(KIT_LOG_DEBUG, "terminal command", cmd)
            `#{cmd}`
        rescue => e
            kit_log(KIT_LOG_PANIC, "[ERROR]", e, session)
            redirect to('/')
        end
        redirect to('/kit_admin')

     end

     get '/bash_command' do
        kit_log(KIT_LOG_INFO, '/bash_command')
        is_admin
        session!

        cmd = params["cmd"]

        begin
            kit_log(KIT_LOG_DEBUG, "terminal command", cmd)
            `#{cmd}`
        rescue => e
            kit_log(KIT_LOG_PANIC, "[ERROR]", e, session)
            redirect to('/')
        end
        redirect to('/kit_admin')
    end

    def get_kit_log_level
        kit_log(KIT_LOG_INFO, '/get_kit_log_level')
        session!
        query = " SELECT value FROM kit_config WHERE is_valid = true AND property = 'LOG_LEVEL'; "
        begin
            kit_log(KIT_LOG_DEBUG, "query", query)
            ret = @@conn.exec(query)
        rescue => e
            kit_log(KIT_LOG_PANIC, "[ERROR]", e, session, query)
            redirect to('/')
        end
        kit_log(KIT_LOG_VERBOSE, "ret.fields", ret.fields)
        kit_log(KIT_LOG_DEBUG, "ret.values", ret.values)

        @kit_log_level = ret.first["value"].to_s;

        if @kit_log_level == 'KIT_LOG_DEBUG'
            $logging_level = KIT_LOG_DEBUG
        elsif @kit_log_level == 'KIT_LOG_VERBOSE'
            $logging_level = KIT_LOG_VERBOSE
        elsif @kit_log_level == 'KIT_LOG_INFO'
            $logging_level = KIT_LOG_INFO
        elsif @kit_log_level == 'KIT_LOG_ERROR'
            $logging_level = KIT_LOG_ERROR
        elsif @kit_log_level == 'KIT_LOG_PANIC'
            $logging_level = KIT_LOG_PANIC
        end

        kit_log(KIT_LOG_VERBOSE, "@kit_log_level value", @kit_log_level)
    end

    def get_distinct_log_level
        kit_log(KIT_LOG_INFO, '/get_distinct_log_level', session[:uid], session[:username])
        is_admin
        session!
        query = " SELECT DISTINCT value FROM kit_config WHERE property = 'LOG_LEVEL'; "
        begin
            kit_log(KIT_LOG_DEBUG, "query", query)
            ret = @@conn.exec(query)
        rescue => e
            kit_log(KIT_LOG_PANIC, "[ERROR]")
            kit_log(KIT_LOG_PANIC, e, session)
            redirect to('/')
        end
        kit_log(KIT_LOG_VERBOSE, "ret.fields", ret.fields)
        kit_log(KIT_LOG_DEBUG, "ret.values", ret.values)
        log_levels = [];
        ret.each do |level|
            log_levels << {
                :value => level["value"],
            }
        end
        @log_levels = log_levels;
    end
end




=begin
DROP TABLE kit_config;
CREATE TABLE kit_config
(
  id serial NOT NULL,
  property character varying NOT NULL,
  is_valid boolean DEFAULT false,
  value character varying NOT NULL,
  description character varying,
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone DEFAULT now(),
  is_unique boolean DEFAULT false,
  CONSTRAINT kit_config_pkey PRIMARY KEY (id),
  CONSTRAINT unique_property_value UNIQUE (property, value)
);

insert into kit_config (property , is_valid , value , description) values ('ADMIN_USER' , true  , 'snk'             , 'User with administrator previleges');
insert into kit_config (property , is_valid , value , description) values ('LOG_LEVEL'  , false , 'KIT_LOG_DEBUG'   , 'KIT_LOG_DEBUG');
insert into kit_config (property , is_valid , value , description) values ('LOG_LEVEL'  , true  , 'KIT_LOG_VERBOSE' , 'KIT_LOG_VERBOSE');
insert into kit_config (property , is_valid , value , description) values ('LOG_LEVEL'  , false , 'KIT_LOG_INFO'    , 'KIT_LOG_INFO');
insert into kit_config (property , is_valid , value , description) values ('LOG_LEVEL'  , false , 'KIT_LOG_PANIC'   , 'KIT_LOG_ERROR');
insert into kit_config (property , is_valid , value , description) values ('LOG_LEVEL'  , false , 'KIT_LOG_PANIC'   , 'KIT_LOG_PANIC');
=end

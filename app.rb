require "bundler/setup"

Bundler.require

module Rally_Metrics
  class App < Sinatra::Base

    # Set up some useful methods
    def self.root_path(*args); File.join(self.root, *args); end
    def self.root_glob(*args, &block); Dir.glob(root_path(*args), &block); end
    def self.route_files(&block); root_glob("routes", "**", "*.rb", &block); end
    def root_path(*args); self.class.root_path(*args); end
    def root_glob(*args, &block); self.class.root_glob(*args, &block); end

    configure do
      set :root, ::File.dirname(__FILE__)

      # Must set this to false to tell Sinatra to throw errors up
      # the stack instead of just showing the built in error page.
      set :show_exceptions, false

      enable :logging

      # setup logger
      FileUtils.mkdir_p root_path("log")
      logger = Logger.new(root_path("log", "#{environment}.log"))

      if production?
        set :logger_level, :error
        logger.level = Logger::ERROR
      else
        set :logger_level, :debug
        logger.level = Logger::DEBUG
      end

      $logger = logger

      helpers do
        alias_method :h, :escape_html
        def config
          Rally_Metrics::App.config
        end
        root_glob("lib", "helpers", "*.rb").each do |h|
          load h
        end
      end

      require root_path("lib","rally_metrics","rally_metrics.rb")

    end

    # load fake controllers... what we think as of routes.
    root_glob("routes", "*.rb").each do |c|
      load c
    end

  end
end

# define default port if launched directly via "ruby app.rb"
#
# Sinatra times-out before data can be returned,
# so the best way to run the app is via Thin or Rackup
#   "bin/thin -a 127.0.0.1 -p 4567 --debug -V --rackup config.ru start"
#   "bin/rackup -o 127.0.0.1 -p 4567 -s thin"

if $0 == __FILE__

  Rally_Metrics::App.run!(:bind => ((ARGV[0].nil?) ? '127.0.0.1' : ARGV[0]),
                      :port => ((ARGV[1].nil?) ? 4567 : ARGV[1]))
end

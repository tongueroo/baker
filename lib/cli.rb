class Baker
  class CLI
    def self.run(args)
      cli = new(args)
      cli.parse_options!
      cli.run
    end

    # The array of (unparsed) command-line options
    attr_reader :args
    # The hash of (parsed) command-line options
    attr_reader :options

    def initialize(args)
      @args = args.dup
    end

    def option_parser
      # @logger = Logger.new
      @option_parser ||= OptionParser.new do |opts|
        opts.banner = "Usage: #{File.basename($0)} <server>"

        opts.on("-s", "--setup", "sets up chef, must be ran once before you can run chef recipes.") do
          options[:setup] = true
        end

        opts.on("-h", "--help", "Display this help message.") do
          puts opts
          exit
        end

        opts.on("-V", "--version", "Display the baker version, and exit.") do
          puts "Baker Version #{Baker::Version}"
          exit
        end
      end
    end

    def parse_options!
      # defaults
      @options = {:host => '', :setup => false}

      if args.empty?
        warn "Please specifiy the server to run the recipes on."
        warn option_parser
        exit 1
      end

      option_parser.parse!(args)
      options[:host].concat(*args)
    end

    def run
      puts "%%%%%%"
      pp options
      if options[:setup]
        Baker.setup(options)
      else
        Baker.run(options)
      end
    end
  end
end
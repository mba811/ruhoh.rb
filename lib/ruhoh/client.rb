require 'ruhoh/compiler'
require 'ruhoh/console_methods'
require 'irb'

class Ruhoh
  
  class Client
    DefaultBlogScaffold = 'git://github.com/ruhoh/blog.git'
    Help = [
      {
        "command" => "new <directory_path>",
        "desc" => "Create a new blog directory based on the Ruhoh specification."
      },
      {
        "command" => "compile",
        "desc" => "Compile to static website."
      },
      {
        "command" => "help",
        "desc" => "Show this menu."
      }
    ]
    def initialize(data)
      @args = data[:args]
      @options = data[:options]
      @opt_parser = data[:opt_parser]
      @options.ext = (@options.ext || 'md').gsub('.', '')
      @ruhoh = Ruhoh.new
      cmd = (data[:args][0] == 'new') ? 'blog' : (data[:args][0] || 'help')
      
      return self.__send__(cmd) if self.respond_to?(cmd)

      Ruhoh::Friend.say { 
        red "Resource #{cmd} not found"
        exit 
      } unless @ruhoh.resources.exists?(cmd)
      
      @ruhoh.setup
      @ruhoh.setup_paths
      
      client = @ruhoh.resources.client(cmd).new(@ruhoh, data)
      
      Ruhoh::Friend.say { 
        red "method '#{data[:args][1]}' not found for #{client.class}"
        exit 
      } unless client.respond_to?(@args[1])
      
      client.__send__(@args[1])
    end  
    
    # Thanks rails! https://github.com/rails/rails/blob/master/railties/lib/rails/commands/console.rb
    def console
      ARGV.clear # IRB throws an error otherwise.
      require 'pp'
      IRB::ExtendCommandBundle.send :include, Ruhoh::ConsoleMethods
      IRB.start
    end
    
    # Show Client Utility help documentation.
    def help
      options = @opt_parser.help
      resources = [{"methods" => Help}]
      resources += @ruhoh.resources.resources.keys.map {|name|
        next unless @ruhoh.resources.client?(name)
        next unless @ruhoh.resources.client(name).const_defined?(:Help)
        {
          "name" => name,
          "methods" => @ruhoh.resources.client(name).const_get(:Help)
        }
      }.compact
      
      Ruhoh::Friend.say { 
        plain "Ruhoh is a nifty, modular static blog generator."
        plain "It is the Universal Static Blog API."
        plain "Visit http://www.ruhoh.com for complete usage and documentation."
        plain ''
        plain options
        plain ''
        plain 'Commands:'
        plain ''
        resources.each do |resource|
          resource["methods"].each do |method|
            if resource["name"]
              green("  " + "#{resource["name"]} #{method["command"]}")
            else
              green("  " + method["command"])
            end
            plain("    "+ method["desc"])
          end
        end
      }
    end
    
    # Public: Compile to static website.
    def compile
      Ruhoh::Program.compile(@args[1])
    end
    
    # Public: Create a new blog at the directory provided.
    def blog
      name = @args[1]
      scaffold = @args.length > 2 ? @args[2] : DefaultBlogScaffold
      useHg = @options.hg
      Ruhoh::Friend.say { 
        red "Please specify a directory path." 
        plain "  ex: ruhoh new the-blogist"
        exit
      } if name.nil?

      target_directory = File.join(Dir.pwd, name)

      Ruhoh::Friend.say { 
        red "#{target_directory} already exists."
        plain "  Specify another directory or `rm -rf` this directory first."
        exit
      } if File.exist?(target_directory)
      
      Ruhoh::Friend.say { 
        plain "Trying this command:"

        if useHg
          cyan "  hg clone #{scaffold} #{target_directory}"
          success = system('hg', 'clone', scaffold, target_directory)
        else
          cyan "  git clone #{scaffold} #{target_directory}"
          success = system('git', 'clone', scaffold, target_directory)
        end

        if success
          green "Success! Now do..."
          cyan "  cd #{target_directory}"
          cyan "  rackup -p9292"
          cyan "  http://localhost:9292"
        else
          red "Could not git clone blog scaffold. Please try it manually:"
          cyan "  git clone git://github.com/ruhoh/blog.git #{target_directory}"
        end
      }
    end
    
    def ask(message, valid_options)
      if valid_options
        answer = get_stdin("#{message} #{valid_options.to_s.gsub(/"/, '').gsub(/, /,'/')} ") while !valid_options.include?(answer)
      else
        answer = get_stdin(message)
      end
      answer
    end

    def get_stdin(message)
      print message
      STDIN.gets.chomp
    end
    
  end #Client
end #Ruhoh
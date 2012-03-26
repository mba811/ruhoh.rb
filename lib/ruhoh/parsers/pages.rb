class Ruhoh

  module Parsers
    
    module Pages
    
      # Public: Generate the Pages dictionary.
      #
      def self.generate
        raise "Ruhoh.config cannot be nil.\n To set config call: Ruhoh.setup" unless Ruhoh.config

        pages = self.files
        invalid = []
        dictionary = {}

        pages.each do |filename|
          parsed_page = Ruhoh::Utils.parse_file(filename)
          if parsed_page.empty?
            error = "Invalid Yaml Front Matter.\n Ensure this page has valid YAML, even if it's empty."
            invalid << [filename, error] ; next
          end
          
          parsed_page['data']['id']     = filename
          parsed_page['data']['url']    = self.permalink(parsed_page['data'])
          parsed_page['data']['title']  = parsed_page['data']['title'] || self.titleize(filename)

          dictionary[filename] = parsed_page['data']
        end
          
        report = "#{pages.count - invalid.count }/#{pages.count} pages processed."
        
        if pages.count.zero? && invalid.empty?
          Ruhoh::Friend.say { plain "0 pages to process." }
        elsif invalid.empty?
          Ruhoh::Friend.say { green report }
        else
          Ruhoh::Friend.say {
            yellow report
            list "Pages not processed:", invalid
          }
        end

        dictionary 
      end

      def self.files
        FileUtils.cd(Ruhoh.paths.site_source) {
          return Dir["**/*.*"].select { |filename| 
            next unless self.is_valid_page?(filename)
            true
          }
        }
      end
      
      def self.is_valid_page?(filepath)
        return false if FileTest.directory?(filepath)
        return false if ['_', '.'].include? filepath[0]
        return false if Ruhoh.filters.pages['names'].include? filepath
        Ruhoh.filters.pages['regexes'].each {|regex| return false if filepath =~ regex }
        true
      end
    
      def self.titleize(filename)
        name = File.basename( filename, File.extname(filename) )
        name = filename.split('/')[-2] if name == 'index' && !filename.index('/').nil?
        name.gsub(/[\W\_]/, ' ').gsub(/\b\w/){$&.upcase}
      end
    
      def self.permalink(page)
        url = '/' + page['id'].gsub(File.extname(page['id']), '.html')
        # sanitize url
        url = url.split('/').reject{ |part| part =~ /^\.+$/ }.join('/')
        url.gsub!(/\/index.html$/, '')
        url = "/" if url.empty?
        
        url
      end
    
    end # Pages
  
  end #Parsers
  
end #Ruhoh
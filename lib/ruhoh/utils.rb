class Ruhoh
  
  module Utils
    
    FMregex = /^(---\s*\n.*?\n?)^(---\s*$\n?)/m
    ContentRegex = /\{\{\s*content\s*\}\}/i
    
    def self.parse_file_as_yaml(*args)
      filepath = File.__send__ :join, args
      return nil unless File.exist? filepath

      file = File.open(filepath, 'r:UTF-8') {|f| f.read }
      yaml = YAML.load(file) || {}
      yaml
    rescue Psych::SyntaxError => e
      Ruhoh.log.error("ERROR in #{filepath}: #{e.message}")
      nil
    end
    
    def self.parse_file(*args)
      path = File.__send__(:join, args)
      
      raise "File not found: #{path}" unless File.exist?(path)

      page = File.open(path, 'r:UTF-8') {|f| f.read }
      front_matter = page.match(FMregex)

      return {} unless front_matter

      data = YAML.load(front_matter[0].gsub(/---\n/, "")) || {}

      { 
        "data" => self.format_meta(data),
        "content" => page.gsub(FMregex, '')
      }
    rescue Psych::SyntaxError => e
      Ruhoh.log.error("ERROR in #{path}: #{e.message}")
      nil
    end
    
    def self.format_meta(data)
      data['categories'] = Array(data['categories'])
      data['tags'] = Array(data['tags'])
      data
    end
    
  end
  
end #Ruhoh
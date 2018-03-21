# -*- encoding : utf-8 -*-
require 'yaml'
require 'clipboard'
#windows
#   require 'ffi'

class YmlKeys 
   def initialize(f = nil , a = nil, l = 'fr')
      @folder = f
      @locale = l
      @alias = a.nil? ? @folder : a  	
      @path = "app/views/#{@folder}/" 
   end   

   def repeated
      to_delete = []      
      load_file
      @keys.keys.each do |k|
         if @keys.has_key?(k)         
            puts("\n#{k}")
         end
      end         
   end


   def clear
      to_delete = []
      to_save = []
      load_file
      @keys.keys.each do |k|         
         if exist?(":#{k}", false) == true 
            to_save << k            
         else
            to_delete << k
            @keys.delete(k)           
         end
      end  

      if to_delete.size > 1
         msg = "Saved Keys : #{to_save.size}, Time : #{Time.now}"
         create_file("locale.#{@locale}_saved_keys.yml", msg , to_save)
         msg = "Deleted Keys : #{to_delete.size}, Time : #{Time.now}"
         create_file("locale.#{@locale}_deleted_keys.yml", msg , to_delete)
         create_yml
         @keys.each do |k| 
            fill_yml(k)   
         end
      else
         puts("All the #{@keys.size} exist, the yml file is updated")
      end     
      return true
   end 

   def k
      Clipboard.copy("K_I18N_ENGLISH_INSIDE = true")      
      puts('K_I18N_ENGLISH_INSIDE = true')
   end

   def create_file(title, msg, data)
      File.open("#{@path}/#{title}", "w+") do |f|
         f.puts(msg) 
         data.each { |element| f.puts("  #{element}") }
      end             
   end 


   def exist?(query = nil, log = true)
      query = Clipboard.paste if query.nil?
      results = []         
      entries

      entries.each do |file|
         #names = File.readlines("#{@path}/#{file}")
         #matches = names.select { |name| name[/#{query}/] }
         #results << matches
         unless File.directory?(File.join(@path, file))
            if accepted?(file)
               File.foreach("#{@path}#{file}") do |line|               
                  results << line if line["#{query}"]
               end            
            end
         end
      end

      if results.size > 0
         puts "Yes, #{query}  has #{results.size} matches" if log
         return true
      else
         puts "No, #{query}  has no matches"         
      end
         
      return false                 
   end

   def accepted?(file)
      f = file.split('.').last          
      return false if f == 'yml'
      return false if f == 'html'
      return true
   end

   def setdir
      puts Dir.getwd
   end

   def entries         
      tmpd = Dir.getwd
      #"/var/www/incwo-dev/dev-bo"
      Dir.chdir(@path)      
      rbfiles = File.join("**", "*")
      entries = Dir.glob(rbfiles)
      Dir.chdir(tmpd)      
      return entries
   end

   def self.get_folders
      tmpd = Dir.getwd
      #"/var/www/incwo-dev/dev-bo"
      Dir.chdir('app/views/')      
      rbfiles = File.join("**")
      entries = Dir.glob(rbfiles)
      Dir.chdir(tmpd)      
      return entries
   end

   def self.next
      results = []
      folders = self.get_folders
      folders.each do |folder|
         if File.file?(File.join("app/views/#{folder}", 'locale.fr.yml'))
         else
            results << folder
         end
      end
      return YmlKeys.new(results[0])     
   end

   def self.left
      results = []
      folders = self.get_folders
      folders.each do |folder|
         if File.file?(File.join("app/views/#{folder}", 'locale.fr.yml'))
         else
            results << folder
         end
      end
      return results.sort
   end

   def create_yml  
      File.open("#{@path}/locale.#{@locale}.yml", "w+") do |f|
         f.puts("---\n#{@locale}:")
         f.puts("  #{@alias}_key_test: \"test\"")
      end
   end

   def fill_yml(t)
      o = "  #{t[0]}: \"#{t[1]}\""  
      File.open("#{@path}/locale.#{@locale}.yml",'a+') do |file| 
         file.puts(o)
         puts("Added => #{o}")            
      end          
   end 

   def load_file
		#default path for incwo yml files.
		#@path to set a full path
		@yml_path =  "#{@path}locale.#{@locale}.yml"   	
		if @folder.nil? || @path.nil? 
			return "No folder/ No path"	
		else
			@yml = YAML.load_file(@yml_path)  	   	 
			@keys = @yml[@locale]   	
		end
	end   

	def find(t = nil, h = nil, l = nil)
   #windows only
   #t = Clipboard.paste.encode('UTF-8') if t.nil?
      t = Clipboard.paste if t.nil?                                    
      t = t.gsub("\n", " ")
      t = t.gsub("\t", " ")
      r = nil
      load_file   	 
      r = @keys.index(t)
         #r = @keys.index{|x|===t}
      if(r.nil?)
         r = add_key(t)   	 
      else
         puts("Already exists:")
			#puts("#{@keys[r]}")   			
		end
      output(r, h, l)
	end

   def test
      find('Test', nil, nil)
   end

   def findh
     find(nil, true, nil)
   end

   def findl
      find(nil, nil, true)
   end

   def output(k, h = nil, l = nil)   	  
		#puts "I18n.t(:#{k})"
		if h.nil?  
         if l.nil?
            Clipboard.copy("I18n.t(:#{k})")
         else
            Clipboard.copy("I18n.t(:#{k}, :locale => in_language_code)")
         end
      else
         Clipboard.copy("<%= I18n.t(:#{k})%>")
      end                  
      return k
   end

   def i18n
      puts("ready_for_i18n /var/www/incwo-dev/dev-bo/app/views/#{@folder}  /var/www/incwo-dev/dev-bo/app/views/#{@folder} --locale fr --ext '.rhtml' > /var/www/incwo-dev/dev-bo/app/views/#{@folder}/locale.fr.yml")
   end

            
   def add_key(t)         
      key = text_to_key(t)          
      k = "#{@alias}_key_#{key}"
      t = t.gsub('"', '\"')
      o = "  #{k}: \"#{t}\""  
      File.open(@yml_path,'a+') do |file| 
         file.puts(o)
         #puts("Added => #{o}")
         puts("Added")            
      end 
      return k
   end 

   def text_to_key(t)          
      n = transliterate(t)
      #my_string.delete('^a-zA-Z')    
      #n = n.gsub(/(\W|\d)/, "_")            
      n = n.gsub(/(\W)/, "_")
	   #n = n.gsub('"', '\"')			
      n = n.downcase          
      n = n.gsub('__','_')
      n = n.gsub('____','_')
      n = n.gsub('_____','_')            
      return n 
   end

   def transliterate(s)
      default_aproximations if @aproximations.nil?          
      chars = s.split(//)
      chars.each_with_index do |value , index|
         n = nil
         n = @aproximations[value]
         unless (n.nil?)                  
            chars[index] = n
         end
      end                
      return chars.join()
   end

   # extracted from: 
   #https://github.com/svenfuchs/i18n/blob/master/lib/i18n/backend/transliterator.rb
   def default_aproximations 
      @aproximations = {
         "¹"=>"1", "²"=>"2", "³"=>"3", 
         "À"=>"A", "Á"=>"A", "Â"=>"A", "Ã"=>"A", "Ä"=>"A", "Å"=>"A", "Æ"=>"AE",
         "Ç"=>"C", "È"=>"E", "É"=>"E", "Ê"=>"E", "Ë"=>"E", "Ì"=>"I", "Í"=>"I",
         "Î"=>"I", "Ï"=>"I", "Ð"=>"D", "Ñ"=>"N", "Ò"=>"O", "Ó"=>"O", "Ô"=>"O",
         "Õ"=>"O", "Ö"=>"O", "×"=>"x", "Ø"=>"O", "Ù"=>"U", "Ú"=>"U", "Û"=>"U",
         "Ü"=>"U", "Ý"=>"Y", "Þ"=>"Th", "ß"=>"ss", "à"=>"a", "á"=>"a", "â"=>"a",
         "ã"=>"a", "ä"=>"a", "å"=>"a", "æ"=>"ae", "ç"=>"c", "è"=>"e", "é"=>"e",
         "ê"=>"e", "ë"=>"e", "ì"=>"i", "í"=>"i", "î"=>"i", "ï"=>"i", "ð"=>"d",
         "ñ"=>"n", "ò"=>"o", "ó"=>"o", "ô"=>"o", "õ"=>"o", "ö"=>"o", "ø"=>"o",
         "ù"=>"u", "ú"=>"u", "û"=>"u", "ü"=>"u", "ý"=>"y", "þ"=>"th", "ÿ"=>"y",
         "Ā"=>"A", "ā"=>"a", "Ă"=>"A", "ă"=>"a", "Ą"=>"A", "ą"=>"a", "Ć"=>"C",
         "ć"=>"c", "Ĉ"=>"C", "ĉ"=>"c", "Ċ"=>"C", "ċ"=>"c", "Č"=>"C", "č"=>"c",
         "Ď"=>"D", "ď"=>"d", "Đ"=>"D", "đ"=>"d", "Ē"=>"E", "ē"=>"e", "Ĕ"=>"E",
         "ĕ"=>"e", "Ė"=>"E", "ė"=>"e", "Ę"=>"E", "ę"=>"e", "Ě"=>"E", "ě"=>"e",
         "Ĝ"=>"G", "ĝ"=>"g", "Ğ"=>"G", "ğ"=>"g", "Ġ"=>"G", "ġ"=>"g", "Ģ"=>"G",
         "ģ"=>"g", "Ĥ"=>"H", "ĥ"=>"h", "Ħ"=>"H", "ħ"=>"h", "Ĩ"=>"I", "ĩ"=>"i",
         "Ī"=>"I", "ī"=>"i", "Ĭ"=>"I", "ĭ"=>"i", "Į"=>"I", "į"=>"i", "İ"=>"I",
         "ı"=>"i", "Ĳ"=>"IJ", "ĳ"=>"ij", "Ĵ"=>"J", "ĵ"=>"j", "Ķ"=>"K", "ķ"=>"k",
         "ĸ"=>"k", "Ĺ"=>"L", "ĺ"=>"l", "Ļ"=>"L", "ļ"=>"l", "Ľ"=>"L", "ľ"=>"l",
         "Ŀ"=>"L", "ŀ"=>"l", "Ł"=>"L", "ł"=>"l", "Ń"=>"N", "ń"=>"n", "Ņ"=>"N",
         "ņ"=>"n", "Ň"=>"N", "ň"=>"n", "ŉ"=>"'n", "Ŋ"=>"NG", "ŋ"=>"ng",
         "Ō"=>"O", "ō"=>"o", "Ŏ"=>"O", "ŏ"=>"o", "Ő"=>"O", "ő"=>"o", "Œ"=>"OE",
         "œ"=>"oe", "Ŕ"=>"R", "ŕ"=>"r", "Ŗ"=>"R", "ŗ"=>"r", "Ř"=>"R", "ř"=>"r",
         "Ś"=>"S", "ś"=>"s", "Ŝ"=>"S", "ŝ"=>"s", "Ş"=>"S", "ş"=>"s", "Š"=>"S",
         "š"=>"s", "Ţ"=>"T", "ţ"=>"t", "Ť"=>"T", "ť"=>"t", "Ŧ"=>"T", "ŧ"=>"t",
         "Ũ"=>"U", "ũ"=>"u", "Ū"=>"U", "ū"=>"u", "Ŭ"=>"U", "ŭ"=>"u", "Ů"=>"U",
         "ů"=>"u", "Ű"=>"U", "ű"=>"u", "Ų"=>"U", "ų"=>"u", "Ŵ"=>"W", "ŵ"=>"w",
         "Ŷ"=>"Y", "ŷ"=>"y", "Ÿ"=>"Y", "Ź"=>"Z", "ź"=>"z", "Ż"=>"Z", "ż"=>"z",
         "Ž"=>"Z", "ž"=>"z", "·"=>"_", "¿"=>"_", "¡"=>"_" 
      }
   end
end


#para mejorar : keys mas cortas. buscar entre keys para generarlas
#borrar desde consola 
#editar keys
#escapear comillas internas 
#revisar keys repetidas
#revison de textto caracter por caracter 

#unused code    
   #File.open("app/views/#{@folder}/locale.fr.yml",  'w') do |h| 
   # h.write @yml
   #end
   #k[key] = test
      #k = {"fr" =>{ "#{key}" => test}}
      #@yml[@locale]["#{@folder}_test"] = test 
      #@yml << k
      #      File.open("app/views/#{@folder}/locale.fr.yml",  "r") do |f|
      #        f.each_line do |line|
      #        @yml << line
      #        end
   # end
   #string.gsub(/[^\x00-\x7f]/u) do |char|
      #@aproximations[char] || replacement || '?'

   #I18n.available_locales = [:fr]  
   #n = I18n.transliterate(t)
   #  in_language_code = 'fr' if in_language_code.to_s == ''  K_I18N_ENGLISH_INSIDE
#




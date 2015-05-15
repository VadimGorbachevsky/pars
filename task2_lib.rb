class String #FROZEN
  def hash #Расчет контрольной суммы
    code = 0
    self.each_byte {|c| code+=17*c.to_i }
    return code
  end
end

class Group  #FROZEN

  @@id = nil
  
	def initialize(properties_array)
    if properties_array.size == 2
      @@id == nil ? @id = @@id = File.open("memory", "r").gets.split("\t")[0].to_i : @id = @@id += 1
      @path = properties_array[0]
      @name = properties_array[1].to_s.chomp
      @parent_group_id = 0 #default
    end
    if properties_array.size == 4
      @id = properties_array[0]
      @path = properties_array[1]
      @name = properties_array[2].to_s.chomp
      @parent_group_id = properties_array[3]
    end
		
	end
	
	attr_accessor :id, :path, :name,  :parent_group_id

	def to_s
		@id.to_s + "\t" + @path.to_s + "\t" + @name.to_s + "\t" + @parent_group_id.to_s
	end

end


class Good

  @@id = nil
  
	def initialize(properties_array)
    if properties_array.size == 4
      @@id == nil ? @id = @@id = File.open("memory", "r").gets.split("\t")[1].to_i : @id = @@id += 1
      @name = properties_array[0]
      @description = properties_array[1]
      @img_link = properties_array[2]
      @group_id = properties_array[3]
    end
    if properties_array.size == 5
      @@id == nil ? @id = @@id = 1 : @id = @@id += 1
      @name = 'link'
      @description = 'description'
      @img_link = 'img_link'
      @group_id = 'group_id'
    end
    
	end
	
	attr_reader :id, :description, :img_link, :name,  :group_id
	
	def to_s
		@id.to_s + "\t" + @name.to_s + "\t" + @img_link.to_s + "\t" + @group_id.to_s
	end
	
end

class Extractor #FROZEN
  
  	def getter_all(address)
      uri = URI(address)	
      resp = Net::HTTP.get_response(uri)
      File.open("raw_data", "w") { |file| file.puts resp.body }
    end
  	
end

class GroupExtractor<Extractor #FROZEN
  
	def group_parser
    
    hash_sums = IO.read("hash_file")
  	raw_groups = File.open("raw_data", "r")
  	final = File.open("groups", "a")
		
		string = raw_groups.gets
		string = raw_groups.gets
		
		while !string.nil?
      string.gsub!("\t\t\t\t\t\t\t<a href=", "")
      if string.include?("<a data-href=\"/") then
        collection = string.split("<a data-href=\"/")
        collection.each do |string7|
          string7.gsub!("<a data-href=\"", "")
          string7.gsub!("\"", "")
          string7.gsub!("<\/a>", "")
          string7.gsub!("<\/div>", "")
          string7.gsub!(" class=header", "")
          string7.gsub!("\t", '')
          string7.gsub!('</li', '')
          string7.gsub!('<span class=count', '')
          string7.gsub!('<div class=count', '')
          string7.gsub!('<div class=title', '')
          target = /([\d]{1,5}([\s]){1}([\S]){7})/
          string7.gsub!(string7.scan(target)[0][0], "") unless string7.scan(target)[0].nil?
          target = /([\d]{1,4}([\s]){1}([\S]){6})/
          string7.gsub!(string7.scan(target)[0][0], "") unless string7.scan(target)[0].nil?
            if string7.include?(">") then
              properties_array = string7.split(">") 
              group = Group.new(properties_array)
              stream_hash = group.path.hash.to_s
              if !hash_sums.include?(stream_hash) then
                hash_sums += (" " + stream_hash)
                final << group.to_s+"\n" if ( (group.to_s.count("/") <= 2) && (group.name != '') && (group.path != 'reduction') )
                bufer = IO.read("memory")
                bufer = bufer.split("\t")
                bufer[1] = bufer[1].to_i
                bufer[0] = group.id.to_i
                file3 = File.open("memory", "w")
                file3.puts bufer[0].to_s+"\t"+bufer[1].to_s
                file3.close
              end
            end
        end
      end
      string = raw_groups.gets
		end
		
		File.open("hash_file", "w").puts hash_sums
		File.delete("raw_data")
	end
	
	
	def detect_master_groups
    
    group_arr = IO.read("groups").split("\n")
    
    group_arr.map! do |e|
      e.split("\t")
    end
    
    group_arr.select! do |e|
      e != []
    end
    
    for i in (0..group_arr.size-1)
      if group_arr[i][1].count("/") < 2 then
        for k in (0..group_arr.size-1)
          if ( group_arr[k][1].count("/") > group_arr[i][1].count("/") ) && group_arr[k][1].include?(group_arr[i][1]) then
            group_arr[k][3] = group_arr[i][0]
          end
        end
      end
    end
    
    m = File.open("groups", "w")
    group_arr.each do |e|
    m.puts(e[0].to_s.chomp + "\t" + e[1].chomp + "\t" + e[2].chomp + "\t" + e[3].to_s.chomp)
    end
  end
	
end

class GoodsExtractor < Extractor
  
	def deep_group
    bufer = nil
		file = File.open("groups", "r") #MUSTFIX
		string = file.gets
		group = Group.new(file.gets.split("\t")) unless string.nil?
      #while !string.nil?
      3.times do
      	good_parse(group) if group.parent_group_id.to_s.chomp != '0'
      	string = file.gets
      	group = Group.new(string.split("\t")) unless string.nil?
      end
	end	#end deeper
	
	def good_parse(group)
		file2 = File.open(group.path.gsub("\/", '_'), "w")
		@next = "1"

	while @next != "thats all" #Пока страницы не кончились
		
		#Берем страницу и заливаем ее в файл
		p link = @next != "1" ? ARGV[0]+"/"+group.path+"?page="+@next : ARGV[0]+"/"+group.path
		getter_all(link.chomp)
		
		#Берем этот файл
		file = File.open("raw_data", "r")
		string = file.gets
		
		#Парсим его
		next_exist = 0

		
		while !string.nil?
			#Поиск адреса следующего листа, если он имеется.
			if string.include?("<link rel=\"next\" href=\"/"+group.path+"?page=") then
					string.gsub!("<link rel=\"next\" href=\"/"+group.path+"?page=", "")
					string.gsub!("\" />", "")
					@next = string
					next_exist = 1
			end
			
			#Поиск параметров товара	
			if string.include?("catalog-product") then
        properties_array = []
        while !string.include?("bigpreview")
          string = file.gets 
        end
        string = file.gets
        string = file.gets
        string.gsub!("\t", '')
        string.gsub!("<img src=\"", '')
        string.gsub!("\"", '')
        string = string.split(" ")[0]
        if string.include?(".jpg") then
          uri = URI(string) unless File.exist?(string.split("\/")[-1])
          resp = Net::HTTP.get_response(uri) unless File.exist?(string.split("\/")[-1])
          File.open(string.split("\/")[-1], "w") { |img_file| img_file.puts resp.body } unless File.exist?(string.split("\/")[-1])
          properties_array[2] = string.split("\/")[-1] + string.split("\/")[-3]
          4.times{ string = file.gets }
        else
          properties_array[2] = ''
          3.times{ string = file.gets }
        end
         # name
        string.gsub!("\t", '')
        string.gsub!("<a href=", '')
        string.gsub!("</a>", '')
        string.gsub!("</li>", '')
        string.gsub!(" class=\"name\"", '')
        properties_array[0] = string.split(">")[1].chomp
        10.times{ string = file.gets }  #description - артефакт
        string.gsub!("\t", '')
        properties_array[1] = string
        properties_array[3] = group.id
        good = Good.new(properties_array)
        hash_sums = IO.read("hash_file")
        stream_hash = good.name.hash
        if !hash_sums.include?(stream_hash.to_s)
          file2.puts good
          hash_sums += (" " + stream_hash.to_s)
          bufer = IO.read("memory")
          bufer = bufer.split("\t")
          bufer[0] = bufer[0].to_i
          bufer[1] = good.id.to_i
          file3 = File.open("memory", "w")
          file3.puts bufer[0].to_s+"\t"+bufer[1].to_s
          file3.close  
        end
        File.open("hash_file", "w"){|f| f.puts hash_sums}
        bufer = IO.read("memory")
        bufer = bufer.split("\t")
			end
			#Взятие следующей
			string = file.gets
		end #end while
		
		
		next_exist == 0 ? @next = "thats all" : ''
  end #end lising while
		file2.close
		File.open("goods", "a") << IO.read(group.path.gsub("\/", '_')) 
		File.delete(group.path.gsub("\/", '_'))
	end #end parsing goods
	
end

class Statist
  def output
    good_arr = []
    group_arr = []
    good_arr_id_gr = []
    groups_arr_id_gr = []
    groups = IO.read("groups")
    puts "Groups:"
    group_arr = groups.split("\n")
    p group_arr.size
    goods = IO.read("goods")
    goods_arr = goods.split("\n")
    puts "Goods:"
    p goods_arr.size
    puts "in groups with id-es:".chomp
    
    goods_arr.map! do |e|
      e.split("\t")
    end
    group_arr.map! do |e|
      e.split("\t")
    end
    
    goods_arr.each do |good_i|
      good_arr_id_gr << good_i[3]
    end
    p good_arr_id_gr.uniq
   
    puts "in master_groups with id-es"
    group_arr.each do |e|
      if good_arr_id_gr.uniq.include?(e[0]) then
        groups_arr_id_gr << e[3]
      end
    end
    p groups_arr_id_gr.uniq
  end
end
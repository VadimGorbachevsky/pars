require 'mechanize'
require 'date'
require 'json'

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
      @@id == nil ? @id = @@id =
File.open("memory","r").gets.split("\t")[0].to_i : @id = @@id += 1
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
    @id.to_s + "\t" + @path.to_s + "\t" + @name.to_s + "\t" +
@parent_group_id.to_s
  end
end


class Good

  @@id = nil
  def initialize(properties_array)
    if properties_array.size == 4
      @@id == nil ? @id = @@id = File.open("memory",
"r").gets.split("\t")[1].to_i : @id = @@id += 1
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

class GroupExtractor
  def group_parser(address)
    hash_sums = IO.read("hash_file")
    final = File.open("groups", "a")
    agent = Mechanize.new
    page  = agent.get(address)
    group_links = page.links_with(node: %r{[ data-href="]{1}})
    group_links.size
    group_links.each do |e|
      properties_array = []
      properties_array[1] = e.text
      properties_array[0] = e.node.attributes.to_s.split("\"")[5].to_s
      group = Group.new(properties_array)
      stream_hash = group.path.hash.to_s
      if !hash_sums.include?(stream_hash) then
        hash_sums += (" " + stream_hash)
        final << group.to_s+"\n"
        bufer = IO.read("memory")
        bufer = bufer.split("\t")
        bufer[1] = bufer[1].to_i
        bufer[0] = group.id.to_i
        file3 = File.open("memory", "w")
        file3.puts bufer[0].to_s+"\t"+bufer[1].to_s
        file3.close
      end
    end
    File.open("hash_file", "w").puts hash_sums
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
      if group_arr[i][1].count("/") <= 2 then
        for k in (0..group_arr.size-1)
          if ( group_arr[k][1].count("/") > group_arr[i][1].count("/")
) && group_arr[k][1].include?(group_arr[i][1]) then
            group_arr[k][3] = group_arr[i][0]
          end
        end
      end
    end
    m = File.open("groups", "w")
    group_arr.each do |e|
    m.puts(e[0].to_s.chomp + "\t" + e[1].chomp + "\t" + e[2].chomp +
"\t" + e[3].to_s.chomp + "\n")
    end
  end

end

class GoodsExtractor
  def deep_group
    bufer = nil
    p "hello"
    file = File.open("groups", "r") #MUSTFIX
    string = file.gets
    group = Group.new(file.gets.split("\t")) unless string.nil?
    #while !string.nil?
      4.times do
        good_parse(group) if group.path.count("/") > 2
        string = file.gets
        group = Group.new(string.split("\t")) unless string.nil?
      end
  end     #end deeper
  def good_parse(group)
    file = File.open("goods", "a")
    @next = ARGV[0]+group.path
    p "hello"
    while @next != "thats all" #Пока страницы не кончились
        #Берем страницу
        p link = @next
        agent = Mechanize.new
        page  = agent.get(link.chomp)
        p "NEXT"
        i = 1
        p @next = page.at("/html/head/link[1]").attributes["href"].value
        
        while !page.at("//*[@id=\"catalog-listing\"]/li[#{i}]").nil?
          properties_array = []
          properties_array[3] = group.id
          properties_array[2] = page.at("//*[@id=\"catalog-listing\"]/li[#{i}]/span[2]/a/img").attributes["src"].value

          uri = URI(properties_array[2]) unless File.exist?(properties_array[2].split("\/")[-1])
          properties_array[2] = properties_array[2].split("\/")[-1]
          resp = Net::HTTP.get_response(uri) unless File.exist?(properties_array[2])
          File.open(properties_array[2], "w") { |img_file| img_file.puts resp.body } unless File.exist?(properties_array[2])

          properties_array[0] = page.at("//*[@id=\"catalog-listing\"]/li[#{i}]/span[3]/a").text
          p good = Good.new(properties_array)
          hash_sums = IO.read("hash_file")
          stream_hash = good.name.hash
          if !hash_sums.include?(stream_hash.to_s)
            file << good.to_s + "\n"
          end
          i += 1
        end
        if @next == group.path &&  i != 1 then
          @next = "thats all";
          i = 1
        else
          p @next = ARGV[0]+@next
        end
        end
    end

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
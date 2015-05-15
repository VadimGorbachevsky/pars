require 'net/http'
require_relative "task2_lib"

group_taker = GroupExtractor.new
group_taker.getter_all(ARGV[0].to_s)
group_taker.group_parser
group_taker.detect_master_groups



good_taker = GoodsExtractor.new
good_taker.deep_group
#File.open("hash_file", 'w') { |a| a << ''}
p "fehsag"
stat= Statist.new
stat.output
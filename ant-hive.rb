#!ruby -Ks

#:include: README
#:include: ChangeLog
#== VERSION
#:include: VERSION

require 'req.rb'

module AntHive
end

if __FILE__==$0
	opt=OptionParser.new
	opt.banner ="ant-hive. \n"
	opt.banner+="--- Search ant's hive deeply, and reveal their world map. :)\n"
	opt.banner+="[usage]\n"
	opt.banner+="ruby ant-hive.rb [-d|-q] -g \n"
	opt.banner+="                 [-d|-q] -H HIVELIST\n"
	opt.banner+="                 [-d|-q] -r PATH [-M MAPLIST] [-R ROUTELIST]\n"
	opt.banner+="                 -h\n"
	opt.banner+="------------------------------------------------------------\n"
	opt.banner+="ant-hive.exe also works. thanks to exerb.\n\n"

	opt_loglevel=Logger::INFO
	opt_gui=false
	opt_root_dir=nil
	opt_map_files=[]
	opt_route_targets=[]
	opt_hives=[]
	opt_fake=false

	opt.on('-d','--debug',"Debug log appears"){|v| opt_loglevel=Logger::DEBUG}
	opt.on('-f','--fake',"Only run for generating exerb recipe."){|v| opt_fake=true }
	opt.on('-g','--gui','Launch GUI window'){|v| opt_gui=true}
	opt.on('-h','--help','Show this message'){|v| puts opt ; exit }
	opt.on('-H','--HIVES= LIST','Run with hive-LIST defined at ant-hive.xml'){|v| opt_hives=v.split(',') }
	opt.on('-M','--MAP= LIST','Generates static map(s) for files in LIST'){|v| opt_map_files=v.split(',') }
	opt.on('-q','--quiet',"Quiet mode.Only displays errors."){|v| opt_loglevel=Logger::ERROR}
	opt.on('-r','--root_dir= PATH','root directory for Ants'){|v| opt_root_dir=v }
	opt.on('-R','--ROUTE= LIST','Generates dynamic route(s) for "target@file" in LIST'){|v|
		v.split(',').each{|target_at_file| 
			opt_route_targets.push target_at_file.split('@').reverse
		}
	}
	opt.parse!(ARGV)

	if opt_gui
		app=AntHive::GUI.new(opt_loglevel)
		app.run
	else
		raise AntHive::AntHiveError.new("-H or -r must be specified. Use -h option for help.") if opt_hives.empty? && ! opt_root_dir
		app=AntHive::CUI.new(opt_loglevel,opt_fake)

		# -H オプションが指定されている場合にはそちらを優先する。
		if ! opt_hives.empty?
			app.load_config_for(opt_hives)
		else
			app.root_directory=opt_root_dir 
			app.map_request(opt_map_files) unless opt_map_files.empty?
			app.route_request(opt_route_targets) unless opt_route_targets.empty?
			app.run
		end
	end

end


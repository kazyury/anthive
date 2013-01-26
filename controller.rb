#!ruby -Ks

module AntHive
	#AntHive�̓��쐧����s���B
	class Controller
		def initialize(fake)
			@logger=SingletonLogger.instance()
			@ui=nil
			@fake=fake
			@root_directory=nil
			@parser=Parser.new()
			@hive=Hive.new()
			@map_generator=MapGraphGenerator.new(@hive)
			@route_generator=RouteTraceGenerator.new(@hive)
			@pfd_generator=PFDGraphGenerator.new(@hive)
			@maplist=[]
			@routelist=[]
			@ui_answer={}
			@logger.debug(self.class){"#{self.class} initiated."}
		end
		attr_reader :hive

		#���[�U�C���^�t�F�[�X��o�^����B
		#
		#[ui] AntHive::CUI �C���X�^���X(����ł�CUI�̂�)
		def ui=(ui)
			@ui=ui
			@logger.debug(self.class){"UI:[ #{@ui.class} ] is selected for user interface."}
		end

		#��͂���ant�t�@�C���Q��root�f�B���N�g�����w�肷��B
		#�]���́A�����Ŏw�肳�ꂽroot�f�B���N�g������_�Ƃ��Aproject ��basedir�������������������ōs����B
		#���݂��Ȃ��f�B���N�g���p�X���w�肵���ꍇ�ɂ͗�OAntHiveError��������B
		#
		#[dir] ��͂���ant�t�@�C���Q�̉��z���[�g�f�B���N�g���̃p�X������������
		def root_directory=(dir)
			raise AntHiveError.new("Root-Directory [ #{dir} ] does not exist.") unless File.directory?(dir)
			@root_directory=dir
			@cache_file=".#{@root_directory.gsub(/\n/,'.')}.cache"
			@logger.debug(self.class){"@root_directory was set to [ #{dir} ]."}
		end

		#Ant�t�@�C���̉�͂�map�̐����˗����󂯓����B
		#maplist �� �t�@�C�����̔z��ł��鎖�����҂���Ă���B
		#
		#[maplist] map�o�͂���Ώ�XML�t�@�C�����̔z��B�Ώ�XML�t�@�C�����͉��z���[�g�f�B���N�g������̑��΃p�X�Ŏw�肳���K�v������B
		def request_for_map(maplist)
			@logger.debug(self.class){"maplist is [ #{maplist.join(',')} ]."}
			@maplist=maplist
		end
		
		#Ant�t�@�C���̉�͂�route�̐����˗����󂯓����B
		#routelist �� [ "�t�@�C����" ,"�^�[�Q�b�g��", {"key1"=>"val1","key2"=>"val2"}, PFD�o�͗v�� ]
		#�̔z��ł��鎖�����҂���Ă���B
		#
		#[routelist] �u"route�o�͂���Ώ�XML�t�@�C���A�^�[�Q�b�g���A�I�v�V����(hash)�APFD�o�͗v��"�̔z��v�̔z��B�Ώ�XML�t�@�C�����͉��z���[�g�f�B���N�g������̑��΃p�X�Ŏw�肳���K�v������B
		def request_for_route(routelist)
			@logger.debug(self.class){"routelist is [ #{disp_string(routelist)} ]."}
			@routelist=routelist
		end

		#�w�肳�ꂽmap,route �̏o�͂��J�n����B
		#1. �������Ă������̐ÓI��͑Ώۃt�@�C���̈ꗗ�𐶐�����B
		#2. �������Ă���S�Ă̐ÓI��͑Ώۃt�@�C������͂���B
		#3. �w�肳�ꂽ���I�o�H�̕]�����s���B(���̉ߒ��Œǉ��̉�͂��s���ꍇ������)
		#4. �w�肳�ꂽroute�̏o�͂����{����B
		#5. �w�肳�ꂽmap�̏o�͂����{����B(���̍ۂɖ��O������UI�ւ̖₢���킹���s��)
		def run
			@logger.info(self.class){"========================================"}
			@logger.info(self.class){"Ant-hive is running with these settings."}
			@logger.info(self.class){"	root_directory    : [ #{@root_directory} ]"}
			@logger.info(self.class){"	request for map   : [ #{@maplist.join(',')} ]"}
			@logger.info(self.class){"	request for route : [ #{disp_string(@routelist)} ]"} unless @routelist.empty?

			# ��͑Ώۃt�@�C���ꗗ�̍쐬
			filelist=@maplist + @routelist.collect{|x| x.first }
			filelist=filelist.sort.uniq
			raise AntHiveError.new("None to parse. Specify any file.") if filelist.empty?
			@logger.debug(self.class){"Parse targets are [ #{filelist.join(',')} ] at this time."}

			# ��͑Ώۃt�@�C���̉��
			filelist.each{|file| parse(file) }

			@routelist.each do |route| 
				file_path,target,options,with_pfd=*route
				options={} unless options

				# routelist�̕]���J�n
				target=evaluate(file_path,target,options)
				@logger.debug(self.class){"Generating each requested route."}

				# route(ROUTE�L�q)�̐���
				generate_route([file_path,target,options])
				
				# route(PFD)�̐���
				generate_pfd([file_path,target,options]) if with_pfd
			end
			
			# �ÓImap�̍쐬
			unless @maplist.empty?
				@logger.debug(self.class){"Generating each requested map."}
				@maplist.each{|map| generate_map_graph(map) } 

				File.open(@cache_file,'w'){|f| @ui_answer.each{|k,v| f.puts "#{k}@@->@@#{v}" } }

				@logger.debug(self.class){"Drawing graphs using graphviz."}
				outfile_path=@map_generator.graph(@fake)
				@logger.info(self.class){"[ #{outfile_path} ] was successfully generated as MAP."}
			end

		end

		#�w�肳�ꂽ�t�@�C���̐ÓI��͂����s�����̌��ʂ�Hive�Ɋi�[����B
		#��͌��ʂ̎Q�Ƃɂ��ẮAAntHive::Hive���Q�Ƃ̂��ƁB
		#root_directory= �ɂĊ�_�f�B���N�g�����ݒ肳��Ă��Ȃ��ꍇ�ɂ́AAntHiveError��O��raise����B
		#
		#[file_path] �ÓI��͑Ώۂ�XML�t�@�C���̉��z���[�g�f�B���N�g������̑��΃p�X������
		def parse(file_path)
			@parser.root_directory = @root_directory unless @parser.root_directory 
			real_path=RealPath.realpath(@root_directory,file_path)

			raise AntHiveError.new("Use AntHive::Controller#root_directory=() to set Root Directory for ants.") unless @root_directory
			raise AntHiveError.new("Ant script file [ #{real_path} ] does not exist.") unless File.file?(real_path)

			@logger.info(self.class){"Starting static-parse for [ #{real_path} ]."}
			result=@parser.parse(real_path)

			@logger.debug(self.class){"Registing result(map) for File:[ #{real_path} ] to Hive."}
			@hive.regist_map(real_path,result)
		end

		#���I�o�H�̕]�����J�n����B
		#ant��xml�t�@�C�����A�^�[�Q�b�g��(nil�̏ꍇ�ɂ́Adefault�����Ŏw�肳�ꂽ�^�[�Q�b�g)�A�y�уI�v�V�����l(Hash)�������ɂƂ�B
		#root_directory= �ɂĊ�_�f�B���N�g�����ݒ肳��Ă��Ȃ��ꍇ�ɂ́AAntHiveError��O��raise����B
		#
		#[file_path] �o�H�]���Ώۂ�XML�t�@�C���̉��z���[�g�f�B���N�g������̑��΃p�X������
		#[target] �o�H�]���Ώۂ̎n�_�^�[�Q�b�g��(nil�̏ꍇ�ɂ́A�o�H�]���Ώ�XML�t�@�C����default�����Ŏw�肳�ꂽ�^�[�Q�b�g)
		#[options] ���s���ɗ^������v���p�e�B���˒l��Hash
		#
		#[returns] �]���̎n�_�ƂȂ����^�[�Q�b�g��
		def evaluate(file_path,target,options)
			raise AntHiveError.new("Use AntHive::Controller#root_directory=() to set Root Directory for ants.") unless @root_directory
			parse_if_not(file_path)
			real_path=RealPath.realpath(@root_directory,file_path)

			str=options.collect{|k,v|"#{k}=>#{v}"}.join(',')

			@logger.info(self.class){"Starting dynamic-evaluation for File:[ #{real_path} ], Target:[ #{target} ], Options:[ #{str} ]."}
			evaluater=Evaluater.new(self,@root_directory,real_path)
			evaluater.options=options
			result=evaluater.evaluate(target)

			@logger.debug(self.class){"Registing result(route) for [ #{target} ] @ [ #{real_path} ] to Hive."}
			#�����^�[�Q�b�g���w�肳��Ă��Ȃ��ꍇ�ɂ́A�]�����ʂ̐擪�^�[�Q�b�g����
			#�����^�[�Q�b�g�𐄒肷��B
			target=result.find{|step| step.target_start? }.current_target unless target
			@hive.regist_route(real_path,target,options,result)
			target
		end

		
		# �ÓI���MAP�𐶐�����B
		# ���ۂɂ́AAntHive::MapGraphGenerator�ɂ�鏈���̈˗��ƁAMapGraphGenerator�ɂĉ����s�\�ȃt�@�C����(��)�̉����̂��߂̃C���^�t�F�[�X��񋟂���B
		# ��
		# (���g�p���܂�)�S�^�[�Q�b�g��MAP�ɏo�͂��邽�߂ɂ́AMAP�����͌o�H�]���Ɋ�Â����ɍs���K�v�����邽�߁A
		# MAP�����̍ۂɂ̓v���p�e�B���Ŏw�肳�ꂽXML�t�@�C�����̉������s���Ȃ��B
		# ���̂��߃��[�U�ɂ��MapGraphGenerator�ւ̏��͂��K�v�ƂȂ�B
		#
		# [file_path] �ÓI���MAP���o�͂���Ώۂ�XML�t�@�C����(���z���[�g�f�B���N�g������̑��΃p�X)
		def generate_map_graph(file_path)
			@map_generator.root_directory = @root_directory unless @map_generator.root_directory 
			parse_if_not(file_path)
			real_path=RealPath.realpath(@root_directory,file_path)

			@logger.debug(self.class){"Generating static map for [ #{real_path} ]."}
			@map_generator.generate(real_path) do |unsolved|
				unless @fake
					if solved_real_path=@ui_answer[unsolved]
						@logger.info(self.class){"Unsolved path:[ #{unsolved} ] was solved as [ #{solved_real_path} ] by user decision."}
						solved_real_path
					else
						keep_decision=false

						statement = "Through generating map:[ #{real_path} ],Unsolved name:[ #{unsolved} ] was appeared.\n"
						statement+= "Enter path name for [ #{unsolved} ] to generate map, with relative-path from [ #{@root_directory} ].\n"
						statement+= "If first string of answer is `[keep]`, remember your selection for [ #{unsolved} ].\n"
						statement+= "If first string of answer is `[file]`, recall your selection from cache file."
						solved_path = @ui.ask(statement)

						# �������̃t�@�C�����ɑ΂���UI������͂��ꂽ�t�@�C���������؂���B
						# ���͂���Ȃ��ꍇ�ɂ͖����B
						# ���͂��ꂽ�ꍇ�ŁA���̃t�@�C�������ۂɑ��݂��Ă���ꍇ�ɂ͒ǉ���generate�������s���B
						# �`����[keep]�ƂȂ��Ă���ꍇ�ɂ́A���̏���@ui_answer�ɂ��i�[����B
						# �`����[file]�ƂȂ��Ă���ꍇ�ɂ́Acache�������ǂݍ��݂��̓��e���g�p����B

						if /\A\[file\]/i=~solved_path
							if File.exist?(@cache_file)
								File.foreach(@cache_file){|line|
									line.chomp!
									key,val=line.split('@@->@@')
									@ui_answer[key]=val
								}
							else
								@ui.tell("cache file is not created.")
							end
							retry
						end

						if solved_path != ""
							if /\A\[keep\]\s/i=~solved_path
								solved_path.sub!(/\A\[keep\]\s/i,'')
								keep_decision=true
							end
							begin
								recursive=true
								solved_real_path = RealPath.realpath(@root_directory,solved_path)
								@ui_answer[unsolved]=solved_real_path if keep_decision
							rescue AntHiveError => e
								@ui.tell("Entered path[ #{solved_path} ] was not found. Ignored.")
								recursive=false
							end
							generate_map_graph(solved_path) if recursive 
						else
							@ui.tell("None was entered. Ignored.")
						end

						solved_real_path
					end
				end
			end

			@logger.info(self.class){"Static map for [ #{real_path} ] was generated."}
		end

		# ���I�]���o�H���𐶐�����B
		# ���ۂɂ́AAntHive::RouteTraceGenerator�ɂ�鏈���̈˗����s���B
		#
		# [route] "route�o�͂���Ώ�XML�t�@�C���A�^�[�Q�b�g���A�I�v�V����(hash)"�̔z��B�Ώ�XML�t�@�C�����͉��z���[�g�f�B���N�g������̑��΃p�X�Ŏw�肳���K�v������B
		def generate_route(route)
			file_path,target,options=*route
			real_path = RealPath.realpath(@root_directory,file_path)
			@logger.debug(self.class){"Generating dynamic route for [ #{target} ]@[ #{real_path} ] with [ #{options} ]."}
			outfile_path=@route_generator.generate(real_path,target,options,@fake)

			# ���O�o�͗p�ɕ���������H
			outfile_dir=File.dirname(outfile_path).gsub(/\\/,'/')
			outfile_name=File.basename(outfile_path)
			outfile_dir[File.expand_path(".")]=''
			outfile_dir[0..0]='' if outfile_dir[0..0]=='/'
			outfile_path=outfile_dir+'/'+outfile_name

			@logger.info(self.class){"[ #{outfile_path} ] was successfully generated for [ #{target} ]@[ #{file_path} ] with [ #{options} ], ROUTE."}
		end
		
		# �o�H����PFD�𐶐�����B
		# ���ۂɂ́AAntHive::PFDGraphGenerator�ɂ�鏈���̈˗����s���B
		#
		# [route] "route�o�͂���Ώ�XML�t�@�C���A�^�[�Q�b�g���A�I�v�V����(hash)"�̔z��B�Ώ�XML�t�@�C�����͉��z���[�g�f�B���N�g������̑��΃p�X�Ŏw�肳���K�v������B
		def generate_pfd(route)
			file_path,target,options=*route
			real_path = RealPath.realpath(@root_directory,file_path)
			@logger.debug(self.class){"Generating PFD for [ #{target} ]@[ #{real_path} ] with [ #{options} ]."}
			outfile_path=@pfd_generator.generate(real_path,target,options,@fake)

			# ���O�o�͗p�ɕ���������H
			outfile_dir=File.dirname(outfile_path).gsub(/\\/,'/')
			outfile_name=File.basename(outfile_path)
			outfile_dir[File.expand_path(".")]=''
			outfile_dir[0..0]='' if outfile_dir[0..0]=='/'
			outfile_path=outfile_dir+'/'+outfile_name

			@logger.info(self.class){"[ #{outfile_path} ] was successfully generated for [ #{target} ]@[ #{file_path} ] with [ #{options} ], PFD."}
		end


		private
		def parse_if_not(file_path)
			real_path=RealPath.realpath(@root_directory,file_path)
			unless @hive.maps[real_path]
				@logger.info("[ #{real_path} ] is not registered to Hive. Parse it first.")
				parse(file_path)
			end
		end

		def disp_string(routelist)
			routelist.collect do |route|
				file=route[0]
				target=route[1]
				if route[2]
					option=route[2].collect{|k,v| "#{k}=>#{v}" }.join(',')
				else
					option=""
				end
				"#{target}@#{file}(#{option})"
			end.join(',')
		end

	end
end


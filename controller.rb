#!ruby -Ks

module AntHive
	#AntHiveの動作制御を行う。
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

		#ユーザインタフェースを登録する。
		#
		#[ui] AntHive::CUI インスタンス(現状ではCUIのみ)
		def ui=(ui)
			@ui=ui
			@logger.debug(self.class){"UI:[ #{@ui.class} ] is selected for user interface."}
		end

		#解析するantファイル群のrootディレクトリを指定する。
		#評価は、ここで指定されたrootディレクトリを基点とし、project のbasedir属性を加味したうえで行われる。
		#存在しないディレクトリパスを指定した場合には例外AntHiveErrorが生じる。
		#
		#[dir] 解析するantファイル群の仮想ルートディレクトリのパスを示す文字列
		def root_directory=(dir)
			raise AntHiveError.new("Root-Directory [ #{dir} ] does not exist.") unless File.directory?(dir)
			@root_directory=dir
			@cache_file=".#{@root_directory.gsub(/\n/,'.')}.cache"
			@logger.debug(self.class){"@root_directory was set to [ #{dir} ]."}
		end

		#Antファイルの解析とmapの生成依頼を受け入れる。
		#maplist は ファイル名の配列である事が期待されている。
		#
		#[maplist] map出力する対象XMLファイル名の配列。対象XMLファイル名は仮想ルートディレクトリからの相対パスで指定される必要がある。
		def request_for_map(maplist)
			@logger.debug(self.class){"maplist is [ #{maplist.join(',')} ]."}
			@maplist=maplist
		end
		
		#Antファイルの解析とrouteの生成依頼を受け入れる。
		#routelist は [ "ファイル名" ,"ターゲット名", {"key1"=>"val1","key2"=>"val2"}, PFD出力要否 ]
		#の配列である事が期待されている。
		#
		#[routelist] 「"route出力する対象XMLファイル、ターゲット名、オプション(hash)、PFD出力要否"の配列」の配列。対象XMLファイル名は仮想ルートディレクトリからの相対パスで指定される必要がある。
		def request_for_route(routelist)
			@logger.debug(self.class){"routelist is [ #{disp_string(routelist)} ]."}
			@routelist=routelist
		end

		#指定されたmap,route の出力を開始する。
		#1. 判明している限りの静的解析対象ファイルの一覧を生成する。
		#2. 判明している全ての静的解析対象ファイルを解析する。
		#3. 指定された動的経路の評価を行う。(その過程で追加の解析を行う場合がある)
		#4. 指定されたrouteの出力を実施する。
		#5. 指定されたmapの出力を実施する。(その際に名前解決にUIへの問い合わせを行う)
		def run
			@logger.info(self.class){"========================================"}
			@logger.info(self.class){"Ant-hive is running with these settings."}
			@logger.info(self.class){"	root_directory    : [ #{@root_directory} ]"}
			@logger.info(self.class){"	request for map   : [ #{@maplist.join(',')} ]"}
			@logger.info(self.class){"	request for route : [ #{disp_string(@routelist)} ]"} unless @routelist.empty?

			# 解析対象ファイル一覧の作成
			filelist=@maplist + @routelist.collect{|x| x.first }
			filelist=filelist.sort.uniq
			raise AntHiveError.new("None to parse. Specify any file.") if filelist.empty?
			@logger.debug(self.class){"Parse targets are [ #{filelist.join(',')} ] at this time."}

			# 解析対象ファイルの解析
			filelist.each{|file| parse(file) }

			@routelist.each do |route| 
				file_path,target,options,with_pfd=*route
				options={} unless options

				# routelistの評価開始
				target=evaluate(file_path,target,options)
				@logger.debug(self.class){"Generating each requested route."}

				# route(ROUTE記述)の生成
				generate_route([file_path,target,options])
				
				# route(PFD)の生成
				generate_pfd([file_path,target,options]) if with_pfd
			end
			
			# 静的mapの作成
			unless @maplist.empty?
				@logger.debug(self.class){"Generating each requested map."}
				@maplist.each{|map| generate_map_graph(map) } 

				File.open(@cache_file,'w'){|f| @ui_answer.each{|k,v| f.puts "#{k}@@->@@#{v}" } }

				@logger.debug(self.class){"Drawing graphs using graphviz."}
				outfile_path=@map_generator.graph(@fake)
				@logger.info(self.class){"[ #{outfile_path} ] was successfully generated as MAP."}
			end

		end

		#指定されたファイルの静的解析を実行しその結果をHiveに格納する。
		#解析結果の参照については、AntHive::Hiveを参照のこと。
		#root_directory= にて基点ディレクトリが設定されていない場合には、AntHiveError例外がraiseする。
		#
		#[file_path] 静的解析対象のXMLファイルの仮想ルートディレクトリからの相対パス文字列
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

		#動的経路の評価を開始する。
		#antのxmlファイル名、ターゲット名(nilの場合には、default属性で指定されたターゲット)、及びオプション値(Hash)を引数にとる。
		#root_directory= にて基点ディレクトリが設定されていない場合には、AntHiveError例外がraiseする。
		#
		#[file_path] 経路評価対象のXMLファイルの仮想ルートディレクトリからの相対パス文字列
		#[target] 経路評価対象の始点ターゲット名(nilの場合には、経路評価対象XMLファイルのdefault属性で指定されたターゲット)
		#[options] 実行時に与えられるプロパティ名⇒値のHash
		#
		#[returns] 評価の始点となったターゲット名
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
			#初期ターゲットが指定されていない場合には、評価結果の先頭ターゲットから
			#初期ターゲットを推定する。
			target=result.find{|step| step.target_start? }.current_target unless target
			@hive.regist_route(real_path,target,options,result)
			target
		end

		
		# 静的解析MAPを生成する。
		# 実際には、AntHive::MapGraphGeneratorによる処理の依頼と、MapGraphGeneratorにて解決不能なファイル名(※)の解決のためのインタフェースを提供する。
		# ※
		# (未使用を含む)全ターゲットをMAPに出力するためには、MAP生成は経路評価に基づかずに行う必要があるため、
		# MAP生成の際にはプロパティ等で指定されたXMLファイル名の解決が行えない。
		# そのためユーザによるMapGraphGeneratorへの助力が必要となる。
		#
		# [file_path] 静的解析MAPを出力する対象のXMLファイル名(仮想ルートディレクトリからの相対パス)
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

						# 未解決のファイル名に対してUIから入力されたファイル名を検証する。
						# 入力されない場合には無視。
						# 入力された場合で、そのファイルが実際に存在している場合には追加のgenerate処理を行う。
						# 冒頭が[keep]となっている場合には、その情報を@ui_answerにも格納する。
						# 冒頭が[file]となっている場合には、cacheから情報を読み込みその内容を使用する。

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

		# 動的評価経路情報を生成する。
		# 実際には、AntHive::RouteTraceGeneratorによる処理の依頼を行う。
		#
		# [route] "route出力する対象XMLファイル、ターゲット名、オプション(hash)"の配列。対象XMLファイル名は仮想ルートディレクトリからの相対パスで指定される必要がある。
		def generate_route(route)
			file_path,target,options=*route
			real_path = RealPath.realpath(@root_directory,file_path)
			@logger.debug(self.class){"Generating dynamic route for [ #{target} ]@[ #{real_path} ] with [ #{options} ]."}
			outfile_path=@route_generator.generate(real_path,target,options,@fake)

			# ログ出力用に文字列を加工
			outfile_dir=File.dirname(outfile_path).gsub(/\\/,'/')
			outfile_name=File.basename(outfile_path)
			outfile_dir[File.expand_path(".")]=''
			outfile_dir[0..0]='' if outfile_dir[0..0]=='/'
			outfile_path=outfile_dir+'/'+outfile_name

			@logger.info(self.class){"[ #{outfile_path} ] was successfully generated for [ #{target} ]@[ #{file_path} ] with [ #{options} ], ROUTE."}
		end
		
		# 経路情報のPFDを生成する。
		# 実際には、AntHive::PFDGraphGeneratorによる処理の依頼を行う。
		#
		# [route] "route出力する対象XMLファイル、ターゲット名、オプション(hash)"の配列。対象XMLファイル名は仮想ルートディレクトリからの相対パスで指定される必要がある。
		def generate_pfd(route)
			file_path,target,options=*route
			real_path = RealPath.realpath(@root_directory,file_path)
			@logger.debug(self.class){"Generating PFD for [ #{target} ]@[ #{real_path} ] with [ #{options} ]."}
			outfile_path=@pfd_generator.generate(real_path,target,options,@fake)

			# ログ出力用に文字列を加工
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


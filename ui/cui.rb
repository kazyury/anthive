#!ruby -Ks

module AntHive
	#= CUI
	#コマンドラインのユーザインタフェースを提供する。
	#とはいっても、コマンドラインオプションの解析は前段階で済んでいるので、
	#具体的には以下の機能のみを実装し、残りはControllerにお任せしている。
	#- コマンドライン向けのLoggerの定義
	#- 若干のユーザとの対話機能
	#- 構成ファイル解析(指定された場合のみ)
	class CUI
		def initialize(loglevel,fake=false)
			@logger=SingletonLogger.instance()
			@logger.level=loglevel
			@logger.info(self.class){"ant-hive is starting. Log level is [ #{@logger.level} ]."}
			@controller=Controller.new(fake)
			@controller.ui=self
		end

		def ask(statement)
			statement.split("\n").each{|stm| tell(stm)}
			print "[ AntHive needs answer ]---> "
			answer = gets.chomp.strip
			answer
		end

		def tell(statement)
			puts "[ AntHive Message ]:"+statement
		end

		def root_directory=(root_dir)
			@controller.root_directory=root_dir
		end
	
		def map_request(maplist)
			@controller.request_for_map(maplist)
		end
	
		# ControllerにROUTE要求の一覧をセットする。
		#
		# [routelist] "ファイル名(String),ターゲット名(String),オプション(Hash),diagram出力の要否(true or false)" の配列
		#
		# [returns] 不定
		def route_request(routelist)
			@controller.request_for_route(routelist)
		end

		# 構成ファイル(ant-hive.xml)の読み込みを行い、AntHive::Controllerへの初期パラメータをセットする。
		#
		# [hivelist] 定義済みHive名を表現する文字列の配列。ex) %w(sample sample2)
		def load_config_for(hivelist)
			@logger.debug(self.class){"Loading config from ant-hive.xml for [ #{hivelist.join(',')} ]."}
			root=REXML::Document.new(File.new('ant-hive.xml')).root

			hivelist.each{|hivename|
				@logger.debug(self.class){"Searching hive named:[ #{hivename} ]."}

				node=nil
				root.elements.each("./hive[@name=\"#{hivename}\"]"){|n| node=n }

				if node
					@logger.debug(self.class){"Hive config named:[ #{hivename} ] was found."}
					root_dir=nil
					map_list=[]
					route_list=[]

					node.elements.each{|hiveconf|
						options={}
						case hiveconf.name
						when 'root_directory'
							self.root_directory=(hiveconf.attributes['path'])
						when 'map'
							map_list.push hiveconf.attributes['file']
						when 'route'
							file=hiveconf.attributes['file']
							target=hiveconf.attributes['target']
							if hiveconf.attributes['with_diagram']=="true"
								with_diagram=true 
							else
								with_diagram=false
							end
							hiveconf.elements.each{|option_element|
								key=option_element.attributes['key']
								val=option_element.attributes['val']
								raise AntHiveError.new("Children of 'route' element should be 'options' only.") unless option_element.name == 'options'
								raise AntHiveError.new("'option' element should have 'key','val' attributes.") unless key && val

								options[key.strip]=val.strip
							}
							route_list.push [ file, target, options, with_diagram ]
							@logger.debug(self.class){"File:[ #{file} ], Target:[ #{target} ], Options:[ #{options} ]"}
						else
						end
					}
					self.map_request(map_list)
					self.route_request(route_list)
					self.run()
				else
					@logger.error(self.class){"Hive config named:[ #{hivename} ] was NOT found."}
				end
			}
		end

		def run
			@controller.run
		end
	end
end


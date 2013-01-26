#!ruby -Ks

module AntHive
	
	#解析済みのAntスクリプトの集積所
	class Hive

		# 1本の経路を表現するクラス
		# 実体は、EvaluatedStepの配列(@route)を中心として、
		# 経路開始時の情報としてのファイル名と開始ターゲット名を属性として持つ
		class Route
			def initialize(file,entry_point,options,route)
				@file=file
				@entry_point=entry_point
				@options=options
				@route=route
			end
			attr_reader :file, :entry_point, :options, :route

			#自らの@optionsと同一のoptionsが指定されたならば真
			#
			#[options] 動的経路評価開始時のプロパティ名⇒値のHash
			def same_option?(options={})
				ret=true
				@options.each do |key, val|
					ret=false unless options.has_key?(key) # options does not contain my key
					ret=false unless options[key] == val   # options[key] is not same as mine
				end
				options.each do |key, val|
					ret=false unless @options.has_key?(key) # I dont have such a key.
					ret=false unless @options[key] == val   # my val is not same with options
				end
				ret
			end

			#評価済み経路情報(@route == [ EvaluatedStep, ...])を返却する。
			def to_a; @route.dup; end

			#評価済み経路情報(@route == [ EvaluatedStep, ...])をyieldする。
			def each; @route.each{|step| yield step}; end

			def to_s
				"#{@entry_point}@#{File.basename(file,'.xml')}("+@options.collect{|k,v| "#{k}=#{v}"}.join(',') +")"
			end
		end

		# 初期化を行う。
		def initialize()
			@logger=SingletonLogger.instance()
			@maps={}
			@routes=[]
			@logger.debug(self.class){"#{self.class} initiated."}
		end

		def map_entries; @maps.keys.sort; end
		def maps; @maps; end
		def regist_map(file,map); @maps[file]=map; end
		def registed_map?(file)
			@maps[file] ? true : false
		end

		# routeの一覧を返却する。
		def route_entries
			@routes.collect{|r| r.to_s }.sort
		end

		#指定されたrouteの情報を返却する。
		#
		#[file] 動的経路評価対象ファイル名(ant-hiveから解決可能な実際のファイルパス。仮想ルートからのパスではない。)
		#[entry_point] 動的経路評価対象の始点ターゲット名(nilは不可)
		#[options] 動的経路評価を実施した際のプロパティ名⇒値のHash
		def routes(file,entry_point,options)
			@logger.warn(self.class){"Requested route (File:[ #{file} ] EntryPoint:[ #{entry_point} ]) is not set."} unless registed_route?(file,entry_point,options)
			@routes.find_all{|r| r.file==file && r.entry_point==entry_point && r.same_option?(options)}.first
		end

		#指定されたroute情報が未登録ならば、Hiveに登録する。
		#
		#[file] 動的経路評価対象ファイル名(ant-hiveから解決可能な実際のファイルパス。仮想ルートからのパスではない。)
		#[entry_point] 動的経路評価対象の始点ターゲット名(nilは不可)
		#[options] 動的経路評価を実施した際のプロパティ名⇒値のHash
		#[route] 経路評価結果を表現するEvaluatedStepの配列
		def regist_route(file,entry_point,options,route)
			@routes.push(Route.new(file,entry_point,options,route)) unless registed_route?(file,entry_point,options)
		end

		#指定されたrouteが登録されている場合には真、未登録の場合には偽を返却する。
		#
		#[file] 動的経路評価対象ファイル名(ant-hiveから解決可能な実際のファイルパス。仮想ルートからのパスではない。)
		#[entry_point] 動的経路評価対象の始点ターゲット名(nilは不可)
		#[options] 動的経路評価を実施した際のプロパティ名⇒値のHash
		def registed_route?(file,entry_point,options)
			candidates=@routes.find_all{|r| 
				r.file==file && r.entry_point==entry_point && r.same_option?(options)
			}
			if candidates.size==0
				false
			elsif candidates.size==1
				true
			else
				raise AntHiveError.new("[ Bug ] Multiple Route is set.")
			end
		end

	end
end

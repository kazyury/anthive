#!ruby -Ks


module AntHive
	#静的解析の完了したAntスクリプトの評価器。
	class Evaluater

		#Evaluaterにより評価された1ステップを表現するクラス
		#基本情報(@node)は、REXML::Elementであり、付随する情報として、
		#処理中のantファイルパス(root_directoryからの相対) 及び、標識としてのタグ(@tag)を持つ。
		#タグのとりうる値は以下のとおり。
		#[toplevel_start] トップレベルの解析を開始する際に必ず設定されるタグ
		#[toplevel_end] トップレベルの解析を完了する際に必ず設定されるタグ
		#[target_start] ターゲットの解析を開始する際に必ず設定されるタグ
		#[target_end] ターゲットの解析を完了する際に必ず設定されるタグ
		#[step] 各要素について必ず設定されるタグ(現状ではXMLの"閉じタグ"でも設定している)
		#
		#TODO
		#現状では、@tagの種類を増やすのを惜しんで、
		#現状の実装では@nodeはREXML::Element若しくはString(XMLの閉じタグを表現)という、
		#中途半端な実装になっている。
		#- @tagの:stepを、:step_start, :step_end タグに分割
		#- @nodeは常にREXML::Elementを期待するように。...あれ、AntHive::AntObject::Target にもなってる
		#- @tag==:step_end の場合には、@nodeの要素名の閉じタグを表現する
		#- ただし、子要素の無い要素の場合には、:step_start, :step_end を連続させるのか否かについて決定が必要
		class EvaluatedStep
			def initialize(antpath,node,tag)
				@antpath=antpath
				@node=node
				@tag=tag

				@evaluated_value=nil
			end
			attr_reader :tag, :antpath, :node
			attr_accessor :evaluated_value

			# toplevel_start? はトップレベルの解析開始を意味するEvaluatedStepの場合に、真
			# toplevel_end? はトップレベルの解析終了を意味するEvaluatedStepの場合に、真
			# target_start? はターゲット開始を意味するEvaluatedStepの場合に、真
			# target_end? はターゲット終了を意味するEvaluatedStepの場合に、真
			# step? は上記以外を意味するEvaluatedStepの場合に、真
			#
			# [returns] true or false
			def toplevel_start?; @tag==:toplevel_start ;end
			# toplevel_start? を参照
			def toplevel_end?; @tag==:toplevel_end; end
			# toplevel_start? を参照
			def target_start?; @tag==:target_start ;end
			# toplevel_start? を参照
			def target_end?; @tag==:target_end; end
			# toplevel_start? を参照
			def step?; @tag==:step; end

			# target_startタグ若しくはtarget_endタグの場合、ターゲット名を文字列で返却する。
			#
			# [returns] ターゲット名を示す文字列(stepの場合には"")
			def current_target
				(self.target_start? or self.target_end?) ? @node.name : ""
			end

			# EvaluatedStep自身の文字列表現を返却する。
			# ほぼAntHiveのRoute用に特化しているので、通常用途としては使いにくい。
			#
			# [returns] EvaluatedStepの文字列表現
			def to_s
				case @tag
				when :toplevel_start
					"TOPLEVEL @ #{@antpath}"
				when :toplevel_end
					"END OF TOPLEVEL @ #{@antpath}"
				when :target_start
					"Entering target: #{@node.name} @ #{@antpath}\n" +
					"  Depends         : #{@node.depends.join(',')}\n" +
					"  IF-condition    : #{@node.if}\n" +
					"  UNLESS-condition: #{@node.unless}"
				when :target_end
					"Leaving  target: #{@node.name} @ #{@antpath}"
				else
					if @node.is_a?(REXML::Element)
						str= @node.to_s.tosjis.split("\n").first
						str+="\n(( "
						str+=@evaluated_value.to_s.tosjis.split("\n").first
						str+=" ))"
						str
					else
						@node
					end
				end
			end

      # 自身の持つNode名を返却する。
      def node_name
        if @node.is_a?(REXML::Element)
          @node.name
        else
          ""
        end
      end

			# 自身の文字列表現の各行をyieldする。
			def each_line(&b)
				self.to_s.split("\n").each{|line|
					yield line
				}
			end
		end

	# 初期化処理
	#
	# [controller] 呼出元であるcontrollerインスタンス。評価過程で未解析の(Hiveに登録されていない)XMLファイルに遭遇した際に、 Controller に処理を依頼するために必要。
	# [root_dir] 仮想ルートディレクトリを示す文字列
	# [antfile] antfile
	# [logger] Loggerインスタンス
	# [property_table] PropertyTableインスタンス。nilがセットされた場合には新たなブランクのPropertyTableを生成し、自らの@tableとして使用する。
	# [basedir] basedir
	#
	# [returns] 新たなEvaluaterインスタンス
		def initialize(controller,root_dir,antfile,property_table=nil,basedir=nil)
			@logger=SingletonLogger.instance()
			@logger.debug(self.class){"#{self.class} initializing with controller:[ #{controller.class} ],root_dir:[ #{root_dir} ],antfile:[ #{antfile} ]."}
			@controller=controller
			@hive=@controller.hive
			@root_directory=root_dir
			@project=@hive.maps[antfile]
			@default=@project.default
			property_table ? @table=property_table : @table=PropertyTable.new()

			if basedir
				@basedir=basedir
			else
				antfilepath=File.dirname(RelativePath.between(@root_directory,antfile))
				@basedir=antfilepath+"/"+@project.basedir # basedirは最初のAntのみ評価する。
				@expand_basedir=@project.basedir # basedir_expandは最初のAntのみ評価する。
			end

			@options=[]
			@steps=[] # EvaluatedStepの配列
			@logger.debug(self.class){"#{self.class} initiated."}
		end

		# FIXME AS-IS METHOD.
		# Evaluaterがトップレベルの解析を実施しないよう指定する。
		# 
		# [returns] true
		def without_toplevel_eval
			@without_toplevel_eval=true
		end

		# 実行時オプション(プロパティ)を指定する。
		# 引数としては"プロパティ名=>値"(文字列)のHashを期待しているため、
		# 実行時オプションなどで-Dpackage=test -Dnode=build.srv などと指定されている場合には、
		# 前処理でHash化まですんでいる必要がある。
		#
		# [options] "key"=>"val"のHash。ex.) { "package"=>test","node"=>"build.srv" }
		# [returns] 不定
		def options=(options)
			@logger.debug(self.class){"Options:[ #{options} ]."}
			options.each{|key,val|
				key.strip! if key
				val.strip! if val
				@table.regist(key,val)
			}
		end

		# トップレベルの解析が開始した旨のtagを打つ。
		# 実際には、EvaluatedStepの新たなインスタンスを@tag=:toplevel_startで生成してsteps(評価経路情報)に格納する。
		#
		# [returns] 不定
		def toplevel_start()
			@steps.push EvaluatedStep.new(@project.real_path,"",:toplevel_start)
		end

		# トップレベルの解析が終了した旨のtagを打つ。
		# 実際には、EvaluatedStepの新たなインスタンスを@tag=:toplevel_endで生成してsteps(評価経路情報)に格納する。
		#
		# [returns] 不定
		def toplevel_end()
			@steps.push EvaluatedStep.new(@project.real_path,"",:toplevel_end)
		end

		# ターゲットが開始した旨のtagを打つ。
		# 実際には、EvaluatedStepの新たなインスタンスを@tag=:target_startで生成してsteps(評価経路情報)に格納する。
		#
		# [target_node] target要素そのもののREXML::Elementインスタンス
		# [returns] 不定
		def target_start(target_node)
			@steps.push EvaluatedStep.new(@project.real_path,target_node,:target_start)
		end

		# ターゲットが終了した旨のtagを打つ。
		# 実際には、EvaluatedStepの新たなインスタンスを@tag=:target_endで生成してsteps(評価経路情報)に格納する。
		#
		# [target_node] target要素そのもののREXML::Elementインスタンス
		# [returns] 不定
		def target_end(target_node)
			@steps.push EvaluatedStep.new(@project.real_path,target_node,:target_end)
		end

		# ターゲット内の評価ノードである旨のtagを打つ。
		# 実際には、EvaluatedStepの新たなインスタンスを@tag=:stepで生成。
		# 併せて、その対象要素内の${},@{}を展開した内容を、EvaluatedStep#evaluated_valueにセットする。
		# その後にsteps(評価経路情報)に格納する。
		#
		# [target_node] 処理中の要素を示すREXML::Elementインスタンス
		# [replacement] (特にFor要素のため)変換関係を示すHash。例.{"@{rpkg}" => "test" }
		#
		# [returns] 不定
		def node_start_tag(target_node,replacement={})
			evs=EvaluatedStep.new(@project.real_path,target_node,:step)
			evaluated_value=@table.expand(replace_with(replacement,target_node.to_s))
			evs.evaluated_value=evaluated_value
			@steps.push evs
		end
		
		# ターゲット内の評価ノードの終了タグを打つ。
		#
		# [target_node] 処理中の要素を示すREXML::Elementインスタンス
		# [replacement] (特にFor要素のため)変換関係を示すHash。例.{"@{rpkg}" => "test" }
		#
		# [returns] 不定
		def node_end_tag(target_node,replacement={})
			tag_name=target_node.name
			evs=EvaluatedStep.new(@project.real_path,"</#{tag_name}>",:step)
			@steps.push evs
		end

		# targetにて指定されたターゲットの評価を開始する。
		# targetが指定されない場合には、このEvaluaterの@defaultを用いる。
		# (@defaultは、'Hiveに登録済みのこのEvaluaterが評価する対象ファイル'の AntObject::Project#default)
		#
		# self#without_toplevel_evalが設定されていない場合には、プロジェクトスコープの評価を行った後に、対象ターゲットの評価を行う。
		# self#without_toplevel_evalが設定されている場合には、対象ターゲットの評価のみを行う。
		#
		# [target] 評価対象ターゲット名を示す文字列。nilの場合にはデフォルトターゲットを使用する。
		# [returns] EvaluatedStepの配列
		def evaluate(target=nil)
			target ? first_step = target : first_step = @default
			evaluate_project unless @without_toplevel_eval
			evaluate_target(first_step)
			@steps
		end

		# Antのプロジェクトスコープの評価を開始する。
		# 具体的には、antのルート要素である<project>直下の要素の評価を行う。
		# - property要素 : self#evaluate_propertyを呼び出す。
		# - target要素 : この時点では評価しない(後のevaluate_targetにて実施)
		# - その他の要素 : 未実装である旨の警告を表示するのみ。
		def evaluate_project
			@logger.debug(self.class){"Project scope evaluation start for [ #{@project.real_path} ]."}
			raise AntHiveError.new("[BUG] basedir is not set.") unless @basedir
			@logger.debug(self.class){"basedir is [ #{@basedir} ]."}
			@logger.debug(self.class){"traverse all nodes in [ #{@project.real_path} ]."}

			toplevel_start
			@table.regist('basedir',@expand_basedir) unless @table.registed?('basedir')
			
			# 解析された全ノードを辿り、ファイルからのProperty読み込みの場合にはその評価を行う。
			@project.all_nodes.each{|node|

				if node.is_a?(AntObject::Property)
					@logger.debug(self.class){"Property node is processing."}
					node_start_tag(node.source)
					evaluate_property(node.source)
					node_end_tag(node.source) if node.source.has_elements?
				elsif node.is_a?(AntObject::Target)
					# この時点では読み飛ばして構わない
				else
					node_start_tag(node)
					@logger.warn(self.class){"NODE CLASS:[ #{node.class} ] IS IGNORED."}
					node_end_tag(node) if node.has_elements?
				end
			}
			toplevel_end
		end


		#ターゲットの評価を行う。
		#評価順は以下のとおり。
		#1. depends が空ではない場合、dependsに登録されている順に評価を行う。
		#2. ifがnilでない場合、その値がPropertyTableに登録されている場合に限り、評価対象候補とする。
		#3. unlessがnilでない場合、その値がPropertyTableに登録されていない場合に限り、評価対象候補とする。
		#4. 評価対象候補のターゲットである場合、各要素を順に評価する。
		#
		#制約事項：現実装ではtarget内部での条件分岐の評価は行っていないので、callsに登録されている呼び出しは全て実行されるように評価される。
		def evaluate_target(name)

			@logger.debug(self.class){"Target evaluation start for [ #{name} ] @ [ #{@project.real_path} ]."}
			target=@project.find_target(name)
			raise AntHiveError.new("Target:[ #{name} ] was not found.") unless target
			
			# 開始タグを記録
			target_start(target)
			
			# depends 属性の評価
			target.depends.each{|dep|
				@logger.debug(self.class){"Target [ #{name} ] depends on [ #{dep} ].Process it first."}
				evaluate_target(dep)
			}

			# if属性、unless属性を評価したうえで実行可否を判断するためのフラグ
			evaluate_this = true
			
			# if 属性の評価
			if condition_if=target.if
				@logger.debug(self.class){"Target [ #{name} ] needs to be set property:[ #{condition_if} ].Examine it."}
				unless @table.registed?(condition_if)
					@logger.debug(self.class){"Property:[ #{condition_if} ] is not set.Target [ #{name} ] is not evaluated."}
					evaluate_this = false
				else
					@logger.debug(self.class){"Property:[ #{condition_if} ] is set."}
				end
			else
				@logger.debug(self.class){"Target [ #{name} ] has no dependency for 'if' condition."}
			end

			# unless 属性の評価
			if condition_unless=target.unless
				@logger.debug(self.class){"Target [ #{name} ] needs NOT to be set property:[ #{condition_unless} ].Examine it."}
				if @table.registed?(condition_unless)
					@logger.debug(self.class){"Property:[ #{condition_unless} ] is set.Target [ #{name} ] is not evaluated."}
					evaluate_this = false
				else
					@logger.debug(self.class){"Property:[ #{condition_unless} ] is not set."}
				end
			else
				@logger.debug(self.class){"Target [ #{name} ] has no dependency for 'unless' condition."}
			end

			# この時点でevaluate_this が true の場合のみtarget内部の評価を行う。
			if evaluate_this
				@logger.debug(self.class){"Evaluate target [ #{name} ] callings."}
				target.source.elements.each{|elm|
					evaluate_element(elm)
				}
			end
			
			# 終了タグを記録
			target_end(target)
			@logger.debug(self.class){"Target evaluation for [ #{name} ] end."}

			@steps
		end

		# Antスクリプト内の1要素を評価する。
		# 実際には、そのタスクの種類に応じたメソッドを呼び出す。
		#
		# [element] Antスクリプト内の1ノードを表現するREXML::Element
		# [replacement] (特にFor要素のため)変換関係を示すHash。例.{"@{rpkg}" => "test" }
		def evaluate_element(element,replacement={})
			@logger.debug(self.class){"Evaluating element:[ #{element} ]."}

			case element.name
			when 'property'
				@logger.debug(self.class){"Element:[ #{element} ] is property task."}
				node_start_tag(element,replacement)
				evaluate_property(element,replacement)
				node_end_tag(element,replacement) if element.has_elements?
			when 'antcall'
				@logger.debug(self.class){"Element:[ #{element} ] is antcall task."}
				node_start_tag(element,replacement)
				evaluate_antcall(element,replacement)
				node_end_tag(element,replacement) if element.has_elements?
			when 'ant'
				@logger.debug(self.class){"Element:[ #{element} ] is ant task."}
				node_start_tag(element,replacement)
				evaluate_ant(element,replacement)
				node_end_tag(element,replacement) if element.has_elements?
			when 'subant'
				@logger.debug(self.class){"Element:[ #{element} ] is ant task."}
				node_start_tag(element,replacement)
				evaluate_subant(element,replacement)
				node_end_tag(element,replacement) if element.has_elements?
			when 'available'
				@logger.debug(self.class){"Element:[ #{element} ] is available task."}
				node_start_tag(element,replacement)
				evaluate_available(element,replacement)
				node_end_tag(element,replacement) if element.has_elements?
			when 'propertycopy'
				@logger.debug(self.class){"Element:[ #{element} ] is propertycopy task(Ant-Contrib)."}
				node_start_tag(element,replacement)
				evaluate_propertycopy(element,replacement)
				node_end_tag(element,replacement) if element.has_elements?
			when 'for'
				@logger.debug(self.class){"Element:[ #{element} ] is for task(Ant-Contrib)."}
				node_start_tag(element,replacement)
				evaluate_for(element,replacement)
				node_end_tag(element,replacement) if element.has_elements?
			when 'var'
				@logger.debug(self.class){"Element:[ #{element} ] is var task(Ant-Contrib)."}
				node_start_tag(element,replacement)
				evaluate_var(element,replacement)
				node_end_tag(element,replacement) if element.has_elements?
			else
				@logger.debug(self.class){"Element:[ #{element} ] is anon task. Dealing with default procedure only."}
				node_start_tag(element,replacement)
				if element.has_elements?
					element.elements.each{|elm|
						evaluate_element(elm,replacement)
					}
					node_end_tag(element,replacement)
				end
			end

		end

		# antタスクを評価する。
		#
		# [element] antタスクを表現するREXML::Element
		# [replacement] (特にFor要素のため)変換関係を示すHash。例.{"@{rpkg}" => "test" }
		def evaluate_ant(element,replacement={})
			next_file = element.attributes['antfile']
			next_file = 'build.xml' unless next_file
			next_file=replace_with(replacement,next_file)
			next_file=runtime_path(@table.expand(next_file)) # @root_dir + @basedir + @expand_basedir
			next_target=element.attributes['target']
			jump(next_file,next_target,element,replacement)
			@steps
		end

		# subantタスクを評価する。
		#
		# [element] subantタスクを表現するREXML::Element
		# [replacement] (特にFor要素のため)変換関係を示すHash。例.{"@{rpkg}" => "test" }
		def evaluate_subant(element,replacement={})
			# subant の場合、build_pathでファイル名を直接指定する場合もあれば、
			# pathだけを示してファイル名はantfileで指定することも出来る(?)
			# 用途的には、前者の使用方法の方がおかしいような気もするけどよく判らない。
			ant_file  = element.attributes['antfile']
			build_path= element.attributes['buildpath']
			if ant_file && build_path
				next_file = build_path+"/"+ant_file
			elsif ant_file
				next_file = ant_file
			elsif build_path
				build_path=replace_with(replacement,build_path)

				if File.file?(runtime_path(@table.expand(build_path)))
					next_file = build_path
				elsif File.directory?(runtime_path(@table.expand(build_path)))
					next_file = build_path +'/build.xml'
				else
					@logger.error(self.class){"[ BUG ] Is this valid? [ #{runtime_path(@table.expand(build_path))} ]"}
				end
			else
				next_file = 'build.xml'
			end
			next_file=replace_with(replacement,next_file)
			next_file=runtime_path(@table.expand(next_file)) # @root_dir + @basedir + @expand_basedir
			next_target=element.attributes['target']
			jump(next_file,next_target,element,replacement)
			@steps
		end

		# antcallタスクを評価する。
		#
		# [element] antcallタスクを表現するREXML::Element
		# [replacement] (特にFor要素のため)変換関係を示すHash。例.{"@{rpkg}" => "test" }
		def evaluate_antcall(element,replacement={})
			next_file = @project.real_path # 自分自身
			next_target=element.attributes['target']
			jump(next_file,next_target,element,replacement,:without_toplevel)
			@steps
		end

		# antcall/ant/subantタスクの共通メソッド。
		# "次の"ファイル名とターゲット名が確定していることを前提として以下の処理を行う。
		# - "次のファイル"が未解析の場合には、parseを行う。
		# - "次のプロパティ表"を生成する。(inheritAll属性が偽の場合には空のプロパティ表を生成)
		# - "次のプロパティ表"に、子要素で指定されたproperty,paramを登録する。
		# - "次のプロパティ表"を用いて、"次のEvaluater"を生成して、処理を実行させる。
		#
		# [next_file] "次の評価対象ファイル"を示す文字列。この処理に渡される時点で展開済みであることが期待される。
		# [next_target] "次の評価対象ターゲット"を示す文字列。
		# [element] antcall/ant/subantタスクを表現するREXML::Element
		# [replacement] (特にFor要素のため)変換関係を示すHash。例.{"@{rpkg}" => "test" }
		# [without_toplevel] 真を設定した場合には、トップレベルの解析を行わない(antcall用)。デフォルトはfalse。
		def jump(next_file,next_target,element,replacement,without_toplevel=false)
			###############################################
			# next_fileがまだ未解析の場合には解析を行う。
			unless @hive.registed_map?(next_file)
				@logger.debug(self.class){"[ #{next_file} ] is not registered in hive.Requesting to controller for parse."}
				@controller.parse(RelativePath.between(@root_directory,next_file))
			else
				@logger.debug(self.class){"[ #{next_file} ] is already registered in Hive."}
			end

			###############################################
			# 次のEvaluaterに渡すためのPropertyTableを準備
			if element.attributes['inheritAll']=='false'
				next_table=PropertyTable.new
			else
				next_table=@table.deep_copy
			end

			if element.has_elements?
				element.elements.each{|elm|
					if elm.name=='property' || elm.name=='param'
						node_start_tag(elm,replacement)
						evaluate_property(elm,replacement,false,next_table)
						node_end_tag(elm,replacement) if elm.has_elements?
					else
						@logger.error(self.class){"THIS TASK:[ #{elm.name} ] (ANTCALL'S CHILDREN) IS NOT IMPLEMENTED."}
					end
				}
			end

			###############################################
			# 次のEvaluaterを生成して処理をさせる。
			evaluater=Evaluater.new(@controller,@root_directory,next_file,next_table,@basedir)
			evaluater.without_toplevel_eval if without_toplevel

			steps=evaluater.evaluate(next_target)
			@steps+=steps
		end


		# for要素を評価する。(これはAnt-Contribの追加タスクです)
		# list属性の値を取得し、それらをiterateしながら子要素の評価を行う。
		#
		# [element] for要素を表現するREXML::Element
		# [replacement] (特にFor要素のため)変換関係を示すHash。例.{"@{rpkg}" => "test" }
		def evaluate_for(element,replacement={})
			list=element.attributes['list']
			if list
				list=@table.expand(list)
			else
				# list属性が存在しないケースは未実装
				@logger.warn(self.class){"For node NOT have 'list' attribute. Evaluating 'for' may be unstable."}
				element.elements.each{|elm|
					evaluate_element(elm)
				}
				return
			end

			param=element.attributes['param']
			# param属性が存在しないケースは例外
			AntHiveError.new("For node does not have 'param' (Required) attribute.") unless param

			delmiter=element.attributes['delimiter']
			delimiter=','unless delimiter

			list.split(delimiter).each{|entry|
				element.elements.each{|elm|
					evaluate_element(elm,replacement.merge({"@{#{param}}"=>entry}))
				}
			}
		end

		# propertycopy要素を評価する。(これはAnt-Contribの追加タスクです)
		# property属性(又はname属性)のプロパティを、from属性の文字が示すプロパティ値で設定する。
		#
		# [element] propertycopy要素を表現するREXML::Element
		# [replacement] (特にFor要素のため)変換関係を示すHash。例.{"@{rpkg}" => "test" }
		def evaluate_propertycopy(element,replacement={})
			prop_to_set=element.attributes['property']
			prop_to_set=element.attributes['name'] unless prop_to_set
			unless prop_to_set
				@logger.warn(self.class){"propertycopy node does not have 'name' or 'property' attribute.Ignored."}
				return 
			end
			
			if copy_key=element.attributes['from']
				copy_key=replace_with(replacement,copy_key)
				copy_key=@table.expand(copy_key)
				if @table.registed?(copy_key)
					value_to_set=@table.value_for(copy_key)
					@table.regist(prop_to_set, value_to_set)
				else
					@logger.warn(self.class){"Copying key:[ #{copy_key} ] is not registed.Ignored."}
					return
				end
			else
				@logger.warn(self.class){"Propertycopy node does not have 'from' attribute.Ignored."}
				return
			end

		end

		# available要素を評価する。
		# [ asis? ]属性としてfile属性を持つ要素のみ実際の評価を実施する。
		# condition要素のネストした子要素の場合もあるので、property属性が指定されていない場合には、処理を無視する。
		#
		# [element] available要素を表現するREXML::Element
		# [replacement] (特にFor要素のため)変換関係を示すHash。例.{"@{rpkg}" => "test" }
		def evaluate_available(element,replacement={})
			prop_to_set=element.attributes['property']
			unless prop_to_set
				@logger.debug(self.class){"Available node does not have property attribute.Ignored."}
				return 
			end
			value_to_set=element.attributes['value']
			value_to_set='true' unless value_to_set

			if available_file=element.attributes['file']
				@logger.debug(self.class){"Available node has file=[ #{available_file} ] attribute. Expand it."}
				available_file=replace_with(replacement,available_file)
				available_file=@table.expand(available_file)
				@logger.debug(self.class){"Expanded value is [ #{available_file} ]."}

				available_file_runtime=runtime_path(available_file)
				if File.exist?(available_file_runtime)
					@logger.debug(self.class){"File:[ #{available_file_runtime} ] exists. Set property:[ #{prop_to_set} ]."}
					@table.regist(prop_to_set, value_to_set)
				else
					@logger.debug(self.class){"File:[ #{available_file_runtime} ] DOES NOT exists."}
				end
			else
				@logger.warn(self.class){"<Available> element's NOT implemented attribute."}
			end
		end

		# var要素を評価する。(これはAnt-Contribの追加タスクです)
		# 実際には全ての処理をevaluate_propertyに任せてしまう手抜き実装。
		#
		# [element] propertycopy要素を表現するREXML::Element
		# [replacement] (特にFor要素のため)変換関係を示すHash。例.{"@{rpkg}" => "test" }
		def evaluate_var(element,replacement={})
			evaluate_property(element,replacement,true) # mutable=true(可変)としてpropertyの処理をとおす。
		end

		# property要素を評価する。
		# サポートしている属性は以下のとおり。
		# - file=''
		# - name='' and value=''
		#
		# [element] available要素を表現するREXML::Element
		# [replacement] (特にFor要素のため)変換関係を示すHash。例.{"@{rpkg}" => "test" }
		# [mutable] デフォルトはfalse(不変)。本来、propertyは不変なのだが、evaluate_varと実装を共有するために使用
		# [alternate_table] 代替プロパティ表を用いるか否か。真の場合は、代替プロパティ表に対してプロパティを登録する。デフォルトはfalse(代替プロパティ表を用いず、@tableを使用)。
		def evaluate_property(element,replacement={},mutable=false,alternate_table=false )
			alternate_table ? table=alternate_table : table=@table
			mutable ?  word="property" : word="variable"
			
			# <property file="..." >
			if property_file=element.attributes['file']
				@logger.debug(self.class){"#{word} node has file=[ #{property_file} ] attribute. Expand it."}
				property_file=replace_with(replacement,property_file)
				property_file=table.expand(property_file)
				@logger.debug(self.class){"Expanded value is [ #{property_file} ] ."}

				property_file_runtime=runtime_path(property_file)
				if File.exist?(property_file_runtime)
					@logger.debug(self.class){"File:[ #{property_file_runtime} ] exists. Load #{word}."}
					PropertyFile.properties(property_file_runtime){|k,v| table.regist(k,v,mutable) }
				end

			# <property name="..." value="..." />
			elsif element.attributes['name'] 
				property_name=element.attributes['name']

				if element.attributes['value']
					property_value=element.attributes['value']

					@logger.debug(self.class){"#{word} node has name=[ #{property_name} ] and value=[ #{property_value} ] attribute. Expand it."}
					table.regist(property_name, property_value,mutable)
					@logger.debug(self.class){"Registed name=[ #{property_name} ] and value=[ #{property_value} ] #{word} set."}

					property_name=replace_with(replacement,property_name)
					property_value=replace_with(replacement,property_value)
					property_name=table.expand(property_name)
					property_value=table.expand(property_value)
					@logger.debug(self.class){"Expanded value is [ #{property_name} ] and [ #{property_value} ] ."}
				else
					@logger.error(self.class){"IMPLEMENTED #{word.upcase} FOR 'name' ATTRIBUTE IS 'value=' ONLY."}
				end

			# <property environment="env" />
			elsif element.attributes['environment']
				# 実行環境ではないのでとりあえずどうしようもないか。

			# other property tasks
			else
				@logger.error(self.class){"NOT IMPLEMENTED #{word.upcase} ATTRIBUTE."}
			end
		end

		# 実行時のコンテキストを加味した上でのファイルパスを返却する。
		# 具体的には以下の判断を行う。
		# - 指定されたfileが絶対パス表記の場合には、file先頭の/を除去した上で、仮想ルートを基点とした相対パスを構築
		# - 指定されたfileが相対パス表記の場合には、自身が初期化された際の@basedir+@expand_basedir+fileを、仮想ルートを基点とした相対パスで表現
		# - 上記の"仮想ルートからの相対パス"が、実際に存在するならばその値を。実際には存在しないならば、警告を上げた上で適当なパスを返却。
		#
		# [file] 
		def runtime_path(file)
			raise AntHiveError.new("@root_directory is not set.") unless @root_directory
			raise AntHiveError.new("@basedir is not set.") unless @basedir

			# 指定されたfileが絶対パス指定の場合には、先頭に@root_directoryのみをセットして返却
			if /\A\//=~file
				rt_path=file[1..-1]
			else
				rt_path=@basedir+"/"+@expand_basedir.to_s+"/"+file
			end
			begin
				RealPath.realpath(@root_directory,rt_path)
			rescue AntHiveError => e
				@logger.warn(self.class){e.message}
				@root_directory+"/"+@basedir+"/"+file
			end
		end

		def replace_with(replacement, str)
			unless replacement.empty?
				replacement.each{|k,v|
					str.gsub!(Regexp.compile(Regexp.escape(k)),v)
				}
			end
			str
		end
	end
end

#!ruby -Ks

module AntHive
	
	# プロパティを管理するクラス。
	# 実体はHash(@table)だが、キー値の重複制御、値の再帰展開を実装する。
	class PropertyTable

		# 初期化処理を行う。
		#
		# @table :: プロパティ表(varを含む)。プロパティ名⇒プロパティ値のHash。
		# @immutables :: 不変プロパティ名の配列
		def initialize()
			@logger=SingletonLogger.instance()
			@table={} # @tableは、シンプルにString=>Stringのハッシュ。
			@immutables=[]
			@logger.debug(self.class){"#{self.class} initiated."}
		end
		attr_accessor :table, :immutables

		# プロパティテーブルにkeyとvalを格納する。
		# keyとvalはそれぞれStringでなければならない。
		#
		# 格納しようとするkeyが変更不能(mutable:false)で既に登録されている場合には、
		# 更新処理は行わない。(debugログのみ出力。antの処理では既に登録されている情報は上書きされない事を期待して、
		# 何度も同じキーを登録しようとする処理が多いため、ログがうっとうしいので。)
		#
		# key :: プロパティ名を示す文字列
		# val :: プロパティ値を示す文字列(${}が含まれていても構わない)
		# mutable :: デフォルトはfalse。
		#            falseの場合には、一旦プロパティ表に登録されたプロパティ値については、内容を更新する事が出来ない。
		#            trueの場合には、プロパティ表に登録された値が書き換わることがある(主に、Ant-Contrib <var>タスクのため)。
		def regist(key,val,mutable=false)
			raise AntHiveError.new("[ #{key} ] is not String but [ #{key.class} ].") unless key.is_a?(String)
			raise AntHiveError.new("[ #{val} ] is not String but [ #{val.class} ].") unless val.is_a?(String)

			if @table[key]
				@logger.debug(self.class){"Key:[ #{key} ] is already registed as value:[ #{@table[key]} ]."}
				if @immutables.include?(key)
					@logger.debug(self.class){"Ignored to update immutable key:[ #{key} ] => value:[ #{val} (evaluated: #{expand(val)}) ]."}
				else
					@logger.debug(self.class){"Accepted to update mutable key:[ #{key} ] => value:[ #{val} (evaluated: #{expand(val)}) ]."}
					@table[key]=val
					@logger.debug(self.class){"[ #{val} ] was registered for key:[ #{key} ]."}
				end
			else
				@table[key]=val
				@immutables.push key unless @immutables.include?(key)
				@logger.debug(self.class){"[ #{val} ] was registered for key:[ #{key} ]."}
			end
		end

		# keyがプロパティテーブルに登録されているか。
		# - 登録されている場合、true
		# - 登録されていない場合、false
		#
		# key :: プロパティ名を示す文字列
		def registed?(key)
			@table[key] ? true : false
		end

		# keyに対応する値を取得する。デフォルト(expansion=true)では可能な範囲で展開した値を返却する。
		# 対応するキーが登録されていない場合には例外AntHiveErrorを発生させる。
		#
		# key :: プロパティ名を示す文字列
		# expansion :: デフォルトはtrue。
		#              trueの場合には、プロパティ名に対応するプロパティ値を展開して返却する。
		#              falseの場合には、プロパティ名に対応するプロパティ値をそのまま返却する。
		def value_for(key,expansion=true)
			raise AntHiveError.new("Key:[ #{key} ] is not registed.") unless registed?(key)
			if expansion
				self.expand(@table[key])
			else
				@table[key]
			end
		end
		
		# 文字列valを自らのプロパティ表を用いて展開した値を返却する。
		# 展開は、${...}のパタンにマッチした...部分をプロパティ表のキーと見なし、それに対応するプロパティ値の値で変換することで行う。
		# 展開した結果が更に展開可能である場合には、展開処理を行う(再帰)
		#  例. 
		#    srv  => foo
		#    name => ${srv}.co.jp
		#    url  => http://${name}
		#
		#    expand('http://${name}') #=> http://foo.co.jp
		#
		# ${}自体がネストしても構わない
		#  例. 
		#    srv  => foo
		#    foo => 127.0.0.1
		#
		#    expand('${${srv}}') #=> 127.0.0.1
		#
		# str :: 展開を行う文字列
		def expand(str)
			raise AntHiveError.new("[ #{str} ] is not String but [ #{str.class} ].") unless str.is_a?(String)
			@logger.debug(self.class){"expanding [ #{str} ]."}

			# expandable?でなければ、その値をそのまま返却
			return str unless expandable?(str)

			re_scan=false
			# expandables のそれぞれについて処理を行う。
			#
			expandables(str).each do |chunk|
				@logger.debug(self.class){"Check for chunk:[ #{chunk} ]."}

				replace_pattern=Regexp.new(Regexp.escape('${'+chunk+'}'))
				replace_string=@table[chunk]
				
				if replace_string	#@tableに見つかった場合
					@logger.debug(self.class){"Value found for chunk:[ #{chunk} ]."}
					@logger.debug(self.class){"Using [ #{replace_string} ] for [ #{replace_pattern} ], expand [ #{str} ]."}

					# 無限変換防止
					if replace_string[2..-2] == chunk
					else
						re_scan=true
						str.gsub!(replace_pattern,replace_string)
					end
				
				else	#@tableに見つからない場合
					@logger.debug(self.class){"Tended to expand [ #{chunk} ] ,but none in property table."}
				end
			end
			
			# 展開結果が更に展開可能ならば再帰的に処理を行う
			expand(str) if expandable?(str) && re_scan == true

			str
		end

		# 引数文字列が展開可能か否かをtrue又はfalseにて返却する。
		#
		# str :: 展開候補の文字列
		def expandable?(str)
			expandables(str).size == 0 ? false : true
		end

		# 引数文字列を展開可能なchunkに分割してchunkの配列として返却する。
		# chunk文字列は${}の中身の部分のみを返却する。(中身に${,}が含まれていたら、結果値に含まれる)
		# 展開可能な文字列が存在しなければ、結果値のsizeは0となる。
		#
		#  例
		#    expandables('${dir1}/${dir2}/${dir3}') #=> %w(dir1 dir2 dir3)
		#    expandables('/home/kz') #=> %w()
		#    expandables('${本日は${weather}なり}') #=> %w(weather)
		#
		# str :: 展開候補の文字列
		def expandables(str)

			# 1文字ごとに分割して処理
			#
			# - process_1 :: $が見つかった場合にON,$直後の{が見つかったらOFF
			# - process_2 :: $直後の{が見つかったらON,}でOFF
			# - buffer :: process_2がONの時の、文字格納領域
			# - result :: }で確定した文字列の格納領域
			process_1=false
			process_2=false
			buffer=""
			result=[]

			str.split(//).each do |s|
				case s
				when '$'
					process_1=true
				when '{'
					if process_1==true
						process_1=false
						process_2=true
						buffer=""
					end
				when '}'
					process_2=false
					result.push buffer unless buffer==""
					buffer=""
				else
					process_1=false if process_1==true
					buffer << s if process_2==true
				end
			end

			result
		end

		#[FIXME]
		#現状の実装では、ant呼出の際にPropertyTableの(深い)複製を渡すために以下のメソッドを定義しているが、かなりいただけない。

		# Evaluaterがant呼出を評価する際にPropertyTableの(深い)複製を渡すために定義
		# 自らの複製を作成して返却する。
		# 複製のプロパティテーブルについては、自らのプロパティテーブルの深い複製をMarshalを用いて作成している。
		def deep_copy
			new_one=self.class.new()
			new_one.table=Marshal.load(Marshal.dump(@table))
			new_one.immutables=@immutables
			new_one
		end
		
	end
end

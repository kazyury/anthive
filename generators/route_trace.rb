#!ruby -Ks


module AntHive

	module ExcelConst
	end

	module ExcelColumnName

		def self.index(idx)
			self.alphabets[idx].extend ExcelColumnName
		end

		def self.alphabets
			result=[]
			alpha=%w(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)
			result=alpha
			result+=alpha.collect{|alp| "A#{alp}"}
			result+=alpha.collect{|alp| "B#{alp}"}
			result+=alpha.collect{|alp| "C#{alp}"}
			result+=alpha.collect{|alp| "D#{alp}"}
			result+=alpha.collect{|alp| "E#{alp}"}
			result+=alpha.collect{|alp| "F#{alp}"}
			result+=alpha.collect{|alp| "G#{alp}"}
			result+=alpha.collect{|alp| "H#{alp}"}
			result+=alpha.collect{|alp| "I#{alp}"}
			result=result-%w(IW IX IY IZ)
			result
		end

		def alphabets
			ExcelColumnName.alphabets
		end

		def next
			pos=ExcelColumnName.alphabets.index(self)
			self.alphabets[pos+1].extend ExcelColumnName
		end

		def prev
			pos=ExcelColumnName.alphabets.index(self)
			self.alphabets[pos-1].extend ExcelColumnName
		end

	end

	class RouteTraceGenerator
		# 初期化を行う。
		# 特にWin32OLEを用いてExcelを初期化しているため、現時点では環境依存の度合いが強い。
		#
		# [hive] ROUTE情報が格納されたHive
		#
		# [returns] 新たなRouteTraceGeneratorオブジェクト
		def initialize(hive)
			@logger=SingletonLogger.instance()
			@root_directory=nil
			@hive=hive
			@xls=WIN32OLE.new('Excel.Application')
			WIN32OLE.const_load(@xls, ExcelConst)
			@xls.visible=false
			@xls.displayAlerts=false
			@logger.debug(self.class){"#{self.class} initiated."}
		end
		attr_accessor :root_directory

		# Excel版のRouteTraceを生成する。
		# initialize時に指定されたHiveに、引数ので渡されたRoute構成情報が含まれない場合には、例外AntHiveErrorを生じる。
		#
		# [real_pah] routeの基点となるxml(ant)のパスを示す文字列(通常は、root_directoryからの相対パス)
		# [target] routeの基点となるターゲット名を示す文字列
		# [options] 動的経路評価実行時のプロパティ名⇒値のHash
		#
		# [returns] 生成したファイル名を示す文字列
		def generate(real_path,target,options,fake)
			raise AntHiveError.new("[ Bug ] Hive don't have route:[ #{target} ]@[ #{real_path} ] ") unless @hive.registed_route?(real_path,target,options)

			route=@hive.routes(real_path,target,options)
			@logger.debug(self.class){"For requested route( #{target}@#{real_path} ), got [ #{route} ] route info."}

			fso=WIN32OLE.new('Scripting.FileSystemObject')
      outfile=OutFileName.outfile_for_route(route,".xls")
			template=fso.GetAbsolutePathName("generators/template.xlt")
			@logger.debug(self.class){"Outfile for route is [ #{outfile} ]."}

			unless fake
				@logger.warn(self.class){"writing to Microsoft Excel. -- DO NOT USE Excel -- until ends."}
				@book=@xls.workbooks.add(template)

				begin
					create_sheet(route) 
					@book.saveAs(outfile)
				rescue Exception=>e
					@logger.error(self.class){"Exception [ #{e.class} ] raised while creating sheet data."}
					raise e
				ensure
					@book.close
					@xls.quit
				end
			end
			outfile
		end


		private
		
		# 1 route を示す 1シートを作成する。
		#
		# [route] AntHive::Hive::Routeインスタンス
		# [returns] 不定
		def create_sheet(route)
			name=route.to_s
			@logger.debug(self.class){"Copying template sheet to [ #{route.entry_point} ] sheet."}
			#テンプレートシート("template")の全セルを選択し、コピー。
			#その後、新たなシートを作成し、テンプレートシートの全セルをペースト。
			@book.worksheets('template').select
			@book.worksheets('template').range('A1:IV65536').select
			@xls.selection.copy

			@current_sheet=@xls.worksheets.add # <= シートの追加
			@current_sheet.name=route.entry_point
			@current_sheet.paste
			@current_sheet.range("A1").value+=name
			@logger.debug(self.class){"Copying template sheet to [ #{route.entry_point} ] sheet completed."}

			# Routeの情報から最大深度を計算
			depth=max_depth(route)+1
			c_idx_max=ExcelColumnName.index(depth)

			@c_idx="B".extend ExcelColumnName
			@r_idx=2

			# Routeの各stepを走査して転記
			write_steps(route.to_a,c_idx_max)

			# 
			c_idx_expand=ExcelColumnName.index(depth)
			@current_sheet.columns(c_idx_expand+":"+c_idx_expand).entirecolumn.autofit()
		end

		# 格納されているRoute情報を走査し転記を行う。
		# この処理でインデント操作も行う。
		#
		# [steps] EvaluatedStepの配列
		# [c_idx_max]
		#
		# [returns] 
		def write_steps(steps,c_idx_max)

			toplevel_ridx=nil
			toplevel_cidx=nil
			target_start_pos=[] # ターゲット開始時点の位置スタック

			while step = steps.shift

				case step.tag
				when :toplevel_start
					# トップレベル開始時点の行番号・列番号を保持する。
					# 転記時にはデフォルトの列番号のままで、bold転記
					# 転記後、列番号を"次"に移動する。
					@r_idx+=1
					toplevel_ridx=@r_idx
					toplevel_cidx=@c_idx
					fill_step(step,true)
					@c_idx = @c_idx.next

				when :toplevel_end
					# 転記時には列番号を1つ戻して、bold転記
					# toplevel_startの開始時点の行番号・列番号を元に罫線を引く。
					# 最後にトップレベル開始時点の行番号・列番号をクリアする。
					raise AntHiveError.new("[ Bug ] encounted toplevel_end without toplevel_start") unless toplevel_ridx || toplevel_cidx
					@c_idx = @c_idx.prev
					fill_step(step,true)
					draw_border_line(toplevel_cidx, toplevel_ridx, c_idx_max.next, @r_idx-1)
					
					# toplevel 終了後には次にtarget開始が来るはずなので、見た目の微調整のためにここは行番号を増やさない
					#@r_idx+=1

					toplevel_ridx=nil
					toplevel_cidx=nil

				when :target_start
					# ターゲット開始時点の行番号・列番号を保持する。ただし、ターゲット呼出はネストするので、stackに積む。
					# 転記時にはデフォルトの列番号のままで、bold転記
					# 転記後、列番号を"次"に移動する。
					@r_idx+=1
					target_start_pos.push [@r_idx, @c_idx.dup]
					fill_step(step,true)
					@c_idx = @c_idx.next

				when :target_end
					# 転記時には列番号を1つ戻して、bold転記
					# ターゲット開始時点の行番号・列番号を元に罫線を引く。
					target_start=target_start_pos.pop
					raise AntHiveError.new("[ Bug ] pop@target_end returns nil.") unless target_start
					target_start_ridx=target_start.first
					target_start_cidx=target_start.last

					@c_idx = @c_idx.prev
					fill_step(step,true)
					draw_border_line(target_start_cidx, target_start_ridx, c_idx_max.next, @r_idx-1)
					@r_idx+=1

				when :step
					# 転記時にはデフォルトの列番号のままで、通常転記
					# ただし、2行目以降が前行とまったく同一の内容の場合には転記を行わない。
					prev_contents=""
					step.each_line{|line|
						if line == "(( #{prev_contents} ))"
							# do nothing
						else
							fill_line(line)
							@r_idx+=1
						end
						prev_contents=line
					}
				else
					raise AntHiveError.new("[ Bug ] Unknown tag.[ #{step} ]")
				end
			end
		end


		def fill_step(step,bold=false)
			step.each_line{|line|
				fill_line(line, bold)
				@r_idx+=1
			}
		end

		def draw_border_line(c_idx_from, r_idx_from, c_idx_to, r_idx_to)
			range=@current_sheet.range("#{c_idx_from}#{r_idx_from}:#{c_idx_to}#{r_idx_to}")
			[ ExcelConst::XlEdgeTop, ExcelConst::XlEdgeLeft, ExcelConst::XlEdgeRight, ExcelConst::XlEdgeBottom ].each{|edge|
				border=range.borders(edge)
				border.linestyle=ExcelConst::XlContinuous
				border.weight=ExcelConst::XlThin
			}
		end

		# 指定された内容をシートに転記する。
		# ただし、転記内容が (( .... )) の場合には、青字&Italicで転記する。
		#
		# [string] 転記内容
		# [bold] 真の場合にはbold書体で転記する。偽の場合には通常の書体のまま。デフォルトは偽
		#
		# [returns] 不定
		def fill_line(string,bold=false)
			@current_sheet.range("#{@c_idx}#{@r_idx}").value=string
			@current_sheet.range("#{@c_idx}#{@r_idx}").font.bold=bold
			
			# 展開された行の場合には、青字&&Italicにしたい。
			if /\A\(\(.+\)\)\Z/=~string
				@current_sheet.range("#{@c_idx}#{@r_idx}").font.italic=true
				@current_sheet.range("#{@c_idx}#{@r_idx}").font.colorindex=5
			end
		end

		def max_depth(route)
			max_depth=0
			cur_depth=0
			route.each{|step|
				case step.tag
				when :target_start
					cur_depth+=1
					max_depth=cur_depth if cur_depth > max_depth
				when :target_end
					cur_depth-=1
				else
					# nothing to do
				end
			}
			raise AntHiveError.new("[ Bug ] cur_depth is not 0.") unless cur_depth==0
			max_depth
		end
	end
end


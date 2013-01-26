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
		# ���������s���B
		# ����Win32OLE��p����Excel�����������Ă��邽�߁A�����_�ł͊��ˑ��̓x�����������B
		#
		# [hive] ROUTE��񂪊i�[���ꂽHive
		#
		# [returns] �V����RouteTraceGenerator�I�u�W�F�N�g
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

		# Excel�ł�RouteTrace�𐶐�����B
		# initialize���Ɏw�肳�ꂽHive�ɁA�����̂œn���ꂽRoute�\����񂪊܂܂�Ȃ��ꍇ�ɂ́A��OAntHiveError�𐶂���B
		#
		# [real_pah] route�̊�_�ƂȂ�xml(ant)�̃p�X������������(�ʏ�́Aroot_directory����̑��΃p�X)
		# [target] route�̊�_�ƂȂ�^�[�Q�b�g��������������
		# [options] ���I�o�H�]�����s���̃v���p�e�B���˒l��Hash
		#
		# [returns] ���������t�@�C����������������
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
		
		# 1 route ������ 1�V�[�g���쐬����B
		#
		# [route] AntHive::Hive::Route�C���X�^���X
		# [returns] �s��
		def create_sheet(route)
			name=route.to_s
			@logger.debug(self.class){"Copying template sheet to [ #{route.entry_point} ] sheet."}
			#�e���v���[�g�V�[�g("template")�̑S�Z����I�����A�R�s�[�B
			#���̌�A�V���ȃV�[�g���쐬���A�e���v���[�g�V�[�g�̑S�Z�����y�[�X�g�B
			@book.worksheets('template').select
			@book.worksheets('template').range('A1:IV65536').select
			@xls.selection.copy

			@current_sheet=@xls.worksheets.add # <= �V�[�g�̒ǉ�
			@current_sheet.name=route.entry_point
			@current_sheet.paste
			@current_sheet.range("A1").value+=name
			@logger.debug(self.class){"Copying template sheet to [ #{route.entry_point} ] sheet completed."}

			# Route�̏�񂩂�ő�[�x���v�Z
			depth=max_depth(route)+1
			c_idx_max=ExcelColumnName.index(depth)

			@c_idx="B".extend ExcelColumnName
			@r_idx=2

			# Route�̊estep�𑖍����ē]�L
			write_steps(route.to_a,c_idx_max)

			# 
			c_idx_expand=ExcelColumnName.index(depth)
			@current_sheet.columns(c_idx_expand+":"+c_idx_expand).entirecolumn.autofit()
		end

		# �i�[����Ă���Route���𑖍����]�L���s���B
		# ���̏����ŃC���f���g������s���B
		#
		# [steps] EvaluatedStep�̔z��
		# [c_idx_max]
		#
		# [returns] 
		def write_steps(steps,c_idx_max)

			toplevel_ridx=nil
			toplevel_cidx=nil
			target_start_pos=[] # �^�[�Q�b�g�J�n���_�̈ʒu�X�^�b�N

			while step = steps.shift

				case step.tag
				when :toplevel_start
					# �g�b�v���x���J�n���_�̍s�ԍ��E��ԍ���ێ�����B
					# �]�L���ɂ̓f�t�H���g�̗�ԍ��̂܂܂ŁAbold�]�L
					# �]�L��A��ԍ���"��"�Ɉړ�����B
					@r_idx+=1
					toplevel_ridx=@r_idx
					toplevel_cidx=@c_idx
					fill_step(step,true)
					@c_idx = @c_idx.next

				when :toplevel_end
					# �]�L���ɂ͗�ԍ���1�߂��āAbold�]�L
					# toplevel_start�̊J�n���_�̍s�ԍ��E��ԍ������Ɍr���������B
					# �Ō�Ƀg�b�v���x���J�n���_�̍s�ԍ��E��ԍ����N���A����B
					raise AntHiveError.new("[ Bug ] encounted toplevel_end without toplevel_start") unless toplevel_ridx || toplevel_cidx
					@c_idx = @c_idx.prev
					fill_step(step,true)
					draw_border_line(toplevel_cidx, toplevel_ridx, c_idx_max.next, @r_idx-1)
					
					# toplevel �I����ɂ͎���target�J�n������͂��Ȃ̂ŁA�����ڂ̔������̂��߂ɂ����͍s�ԍ��𑝂₳�Ȃ�
					#@r_idx+=1

					toplevel_ridx=nil
					toplevel_cidx=nil

				when :target_start
					# �^�[�Q�b�g�J�n���_�̍s�ԍ��E��ԍ���ێ�����B�������A�^�[�Q�b�g�ďo�̓l�X�g����̂ŁAstack�ɐςށB
					# �]�L���ɂ̓f�t�H���g�̗�ԍ��̂܂܂ŁAbold�]�L
					# �]�L��A��ԍ���"��"�Ɉړ�����B
					@r_idx+=1
					target_start_pos.push [@r_idx, @c_idx.dup]
					fill_step(step,true)
					@c_idx = @c_idx.next

				when :target_end
					# �]�L���ɂ͗�ԍ���1�߂��āAbold�]�L
					# �^�[�Q�b�g�J�n���_�̍s�ԍ��E��ԍ������Ɍr���������B
					target_start=target_start_pos.pop
					raise AntHiveError.new("[ Bug ] pop@target_end returns nil.") unless target_start
					target_start_ridx=target_start.first
					target_start_cidx=target_start.last

					@c_idx = @c_idx.prev
					fill_step(step,true)
					draw_border_line(target_start_cidx, target_start_ridx, c_idx_max.next, @r_idx-1)
					@r_idx+=1

				when :step
					# �]�L���ɂ̓f�t�H���g�̗�ԍ��̂܂܂ŁA�ʏ�]�L
					# �������A2�s�ڈȍ~���O�s�Ƃ܂���������̓��e�̏ꍇ�ɂ͓]�L���s��Ȃ��B
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

		# �w�肳�ꂽ���e���V�[�g�ɓ]�L����B
		# �������A�]�L���e�� (( .... )) �̏ꍇ�ɂ́A��&Italic�œ]�L����B
		#
		# [string] �]�L���e
		# [bold] �^�̏ꍇ�ɂ�bold���̂œ]�L����B�U�̏ꍇ�ɂ͒ʏ�̏��̂̂܂܁B�f�t�H���g�͋U
		#
		# [returns] �s��
		def fill_line(string,bold=false)
			@current_sheet.range("#{@c_idx}#{@r_idx}").value=string
			@current_sheet.range("#{@c_idx}#{@r_idx}").font.bold=bold
			
			# �W�J���ꂽ�s�̏ꍇ�ɂ́A��&&Italic�ɂ������B
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


#!ruby -Ks


module AntHive
	#�ÓI��͂̊�������Ant�X�N���v�g�̕]����B
	class Evaluater

		#Evaluater�ɂ��]�����ꂽ1�X�e�b�v��\������N���X
		#��{���(@node)�́AREXML::Element�ł���A�t��������Ƃ��āA
		#��������ant�t�@�C���p�X(root_directory����̑���) �y�сA�W���Ƃ��Ẵ^�O(@tag)�����B
		#�^�O�̂Ƃ肤��l�͈ȉ��̂Ƃ���B
		#[toplevel_start] �g�b�v���x���̉�͂��J�n����ۂɕK���ݒ肳���^�O
		#[toplevel_end] �g�b�v���x���̉�͂���������ۂɕK���ݒ肳���^�O
		#[target_start] �^�[�Q�b�g�̉�͂��J�n����ۂɕK���ݒ肳���^�O
		#[target_end] �^�[�Q�b�g�̉�͂���������ۂɕK���ݒ肳���^�O
		#[step] �e�v�f�ɂ��ĕK���ݒ肳���^�O(����ł�XML��"���^�O"�ł��ݒ肵�Ă���)
		#
		#TODO
		#����ł́A@tag�̎�ނ𑝂₷�̂�ɂ���ŁA
		#����̎����ł�@node��REXML::Element�Ⴕ����String(XML�̕��^�O��\��)�Ƃ����A
		#���r���[�Ȏ����ɂȂ��Ă���B
		#- @tag��:step���A:step_start, :step_end �^�O�ɕ���
		#- @node�͏��REXML::Element�����҂���悤�ɁB...����AAntHive::AntObject::Target �ɂ��Ȃ��Ă�
		#- @tag==:step_end �̏ꍇ�ɂ́A@node�̗v�f���̕��^�O��\������
		#- �������A�q�v�f�̖����v�f�̏ꍇ�ɂ́A:step_start, :step_end ��A��������̂��ۂ��ɂ��Č��肪�K�v
		class EvaluatedStep
			def initialize(antpath,node,tag)
				@antpath=antpath
				@node=node
				@tag=tag

				@evaluated_value=nil
			end
			attr_reader :tag, :antpath, :node
			attr_accessor :evaluated_value

			# toplevel_start? �̓g�b�v���x���̉�͊J�n���Ӗ�����EvaluatedStep�̏ꍇ�ɁA�^
			# toplevel_end? �̓g�b�v���x���̉�͏I�����Ӗ�����EvaluatedStep�̏ꍇ�ɁA�^
			# target_start? �̓^�[�Q�b�g�J�n���Ӗ�����EvaluatedStep�̏ꍇ�ɁA�^
			# target_end? �̓^�[�Q�b�g�I�����Ӗ�����EvaluatedStep�̏ꍇ�ɁA�^
			# step? �͏�L�ȊO���Ӗ�����EvaluatedStep�̏ꍇ�ɁA�^
			#
			# [returns] true or false
			def toplevel_start?; @tag==:toplevel_start ;end
			# toplevel_start? ���Q��
			def toplevel_end?; @tag==:toplevel_end; end
			# toplevel_start? ���Q��
			def target_start?; @tag==:target_start ;end
			# toplevel_start? ���Q��
			def target_end?; @tag==:target_end; end
			# toplevel_start? ���Q��
			def step?; @tag==:step; end

			# target_start�^�O�Ⴕ����target_end�^�O�̏ꍇ�A�^�[�Q�b�g���𕶎���ŕԋp����B
			#
			# [returns] �^�[�Q�b�g��������������(step�̏ꍇ�ɂ�"")
			def current_target
				(self.target_start? or self.target_end?) ? @node.name : ""
			end

			# EvaluatedStep���g�̕�����\����ԋp����B
			# �ق�AntHive��Route�p�ɓ������Ă���̂ŁA�ʏ�p�r�Ƃ��Ă͎g���ɂ����B
			#
			# [returns] EvaluatedStep�̕�����\��
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

      # ���g�̎���Node����ԋp����B
      def node_name
        if @node.is_a?(REXML::Element)
          @node.name
        else
          ""
        end
      end

			# ���g�̕�����\���̊e�s��yield����B
			def each_line(&b)
				self.to_s.split("\n").each{|line|
					yield line
				}
			end
		end

	# ����������
	#
	# [controller] �ďo���ł���controller�C���X�^���X�B�]���ߒ��Ŗ���͂�(Hive�ɓo�^����Ă��Ȃ�)XML�t�@�C���ɑ��������ۂɁA Controller �ɏ������˗����邽�߂ɕK�v�B
	# [root_dir] ���z���[�g�f�B���N�g��������������
	# [antfile] antfile
	# [logger] Logger�C���X�^���X
	# [property_table] PropertyTable�C���X�^���X�Bnil���Z�b�g���ꂽ�ꍇ�ɂ͐V���ȃu�����N��PropertyTable�𐶐����A�����@table�Ƃ��Ďg�p����B
	# [basedir] basedir
	#
	# [returns] �V����Evaluater�C���X�^���X
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
				@basedir=antfilepath+"/"+@project.basedir # basedir�͍ŏ���Ant�̂ݕ]������B
				@expand_basedir=@project.basedir # basedir_expand�͍ŏ���Ant�̂ݕ]������B
			end

			@options=[]
			@steps=[] # EvaluatedStep�̔z��
			@logger.debug(self.class){"#{self.class} initiated."}
		end

		# FIXME AS-IS METHOD.
		# Evaluater���g�b�v���x���̉�͂����{���Ȃ��悤�w�肷��B
		# 
		# [returns] true
		def without_toplevel_eval
			@without_toplevel_eval=true
		end

		# ���s���I�v�V����(�v���p�e�B)���w�肷��B
		# �����Ƃ��Ă�"�v���p�e�B��=>�l"(������)��Hash�����҂��Ă��邽�߁A
		# ���s���I�v�V�����Ȃǂ�-Dpackage=test -Dnode=build.srv �ȂǂƎw�肳��Ă���ꍇ�ɂ́A
		# �O������Hash���܂ł���ł���K�v������B
		#
		# [options] "key"=>"val"��Hash�Bex.) { "package"=>test","node"=>"build.srv" }
		# [returns] �s��
		def options=(options)
			@logger.debug(self.class){"Options:[ #{options} ]."}
			options.each{|key,val|
				key.strip! if key
				val.strip! if val
				@table.regist(key,val)
			}
		end

		# �g�b�v���x���̉�͂��J�n�����|��tag��łB
		# ���ۂɂ́AEvaluatedStep�̐V���ȃC���X�^���X��@tag=:toplevel_start�Ő�������steps(�]���o�H���)�Ɋi�[����B
		#
		# [returns] �s��
		def toplevel_start()
			@steps.push EvaluatedStep.new(@project.real_path,"",:toplevel_start)
		end

		# �g�b�v���x���̉�͂��I�������|��tag��łB
		# ���ۂɂ́AEvaluatedStep�̐V���ȃC���X�^���X��@tag=:toplevel_end�Ő�������steps(�]���o�H���)�Ɋi�[����B
		#
		# [returns] �s��
		def toplevel_end()
			@steps.push EvaluatedStep.new(@project.real_path,"",:toplevel_end)
		end

		# �^�[�Q�b�g���J�n�����|��tag��łB
		# ���ۂɂ́AEvaluatedStep�̐V���ȃC���X�^���X��@tag=:target_start�Ő�������steps(�]���o�H���)�Ɋi�[����B
		#
		# [target_node] target�v�f���̂��̂�REXML::Element�C���X�^���X
		# [returns] �s��
		def target_start(target_node)
			@steps.push EvaluatedStep.new(@project.real_path,target_node,:target_start)
		end

		# �^�[�Q�b�g���I�������|��tag��łB
		# ���ۂɂ́AEvaluatedStep�̐V���ȃC���X�^���X��@tag=:target_end�Ő�������steps(�]���o�H���)�Ɋi�[����B
		#
		# [target_node] target�v�f���̂��̂�REXML::Element�C���X�^���X
		# [returns] �s��
		def target_end(target_node)
			@steps.push EvaluatedStep.new(@project.real_path,target_node,:target_end)
		end

		# �^�[�Q�b�g���̕]���m�[�h�ł���|��tag��łB
		# ���ۂɂ́AEvaluatedStep�̐V���ȃC���X�^���X��@tag=:step�Ő����B
		# �����āA���̑Ώۗv�f����${},@{}��W�J�������e���AEvaluatedStep#evaluated_value�ɃZ�b�g����B
		# ���̌��steps(�]���o�H���)�Ɋi�[����B
		#
		# [target_node] �������̗v�f������REXML::Element�C���X�^���X
		# [replacement] (����For�v�f�̂���)�ϊ��֌W������Hash�B��.{"@{rpkg}" => "test" }
		#
		# [returns] �s��
		def node_start_tag(target_node,replacement={})
			evs=EvaluatedStep.new(@project.real_path,target_node,:step)
			evaluated_value=@table.expand(replace_with(replacement,target_node.to_s))
			evs.evaluated_value=evaluated_value
			@steps.push evs
		end
		
		# �^�[�Q�b�g���̕]���m�[�h�̏I���^�O��łB
		#
		# [target_node] �������̗v�f������REXML::Element�C���X�^���X
		# [replacement] (����For�v�f�̂���)�ϊ��֌W������Hash�B��.{"@{rpkg}" => "test" }
		#
		# [returns] �s��
		def node_end_tag(target_node,replacement={})
			tag_name=target_node.name
			evs=EvaluatedStep.new(@project.real_path,"</#{tag_name}>",:step)
			@steps.push evs
		end

		# target�ɂĎw�肳�ꂽ�^�[�Q�b�g�̕]�����J�n����B
		# target���w�肳��Ȃ��ꍇ�ɂ́A����Evaluater��@default��p����B
		# (@default�́A'Hive�ɓo�^�ς݂̂���Evaluater���]������Ώۃt�@�C��'�� AntObject::Project#default)
		#
		# self#without_toplevel_eval���ݒ肳��Ă��Ȃ��ꍇ�ɂ́A�v���W�F�N�g�X�R�[�v�̕]�����s������ɁA�Ώۃ^�[�Q�b�g�̕]�����s���B
		# self#without_toplevel_eval���ݒ肳��Ă���ꍇ�ɂ́A�Ώۃ^�[�Q�b�g�̕]���݂̂��s���B
		#
		# [target] �]���Ώۃ^�[�Q�b�g��������������Bnil�̏ꍇ�ɂ̓f�t�H���g�^�[�Q�b�g���g�p����B
		# [returns] EvaluatedStep�̔z��
		def evaluate(target=nil)
			target ? first_step = target : first_step = @default
			evaluate_project unless @without_toplevel_eval
			evaluate_target(first_step)
			@steps
		end

		# Ant�̃v���W�F�N�g�X�R�[�v�̕]�����J�n����B
		# ��̓I�ɂ́Aant�̃��[�g�v�f�ł���<project>�����̗v�f�̕]�����s���B
		# - property�v�f : self#evaluate_property���Ăяo���B
		# - target�v�f : ���̎��_�ł͕]�����Ȃ�(���evaluate_target�ɂĎ��{)
		# - ���̑��̗v�f : �������ł���|�̌x����\������̂݁B
		def evaluate_project
			@logger.debug(self.class){"Project scope evaluation start for [ #{@project.real_path} ]."}
			raise AntHiveError.new("[BUG] basedir is not set.") unless @basedir
			@logger.debug(self.class){"basedir is [ #{@basedir} ]."}
			@logger.debug(self.class){"traverse all nodes in [ #{@project.real_path} ]."}

			toplevel_start
			@table.regist('basedir',@expand_basedir) unless @table.registed?('basedir')
			
			# ��͂��ꂽ�S�m�[�h��H��A�t�@�C�������Property�ǂݍ��݂̏ꍇ�ɂ͂��̕]�����s���B
			@project.all_nodes.each{|node|

				if node.is_a?(AntObject::Property)
					@logger.debug(self.class){"Property node is processing."}
					node_start_tag(node.source)
					evaluate_property(node.source)
					node_end_tag(node.source) if node.source.has_elements?
				elsif node.is_a?(AntObject::Target)
					# ���̎��_�ł͓ǂݔ�΂��č\��Ȃ�
				else
					node_start_tag(node)
					@logger.warn(self.class){"NODE CLASS:[ #{node.class} ] IS IGNORED."}
					node_end_tag(node) if node.has_elements?
				end
			}
			toplevel_end
		end


		#�^�[�Q�b�g�̕]�����s���B
		#�]�����͈ȉ��̂Ƃ���B
		#1. depends ����ł͂Ȃ��ꍇ�Adepends�ɓo�^����Ă��鏇�ɕ]�����s���B
		#2. if��nil�łȂ��ꍇ�A���̒l��PropertyTable�ɓo�^����Ă���ꍇ�Ɍ���A�]���Ώی��Ƃ���B
		#3. unless��nil�łȂ��ꍇ�A���̒l��PropertyTable�ɓo�^����Ă��Ȃ��ꍇ�Ɍ���A�]���Ώی��Ƃ���B
		#4. �]���Ώی��̃^�[�Q�b�g�ł���ꍇ�A�e�v�f�����ɕ]������B
		#
		#���񎖍��F�������ł�target�����ł̏�������̕]���͍s���Ă��Ȃ��̂ŁAcalls�ɓo�^����Ă���Ăяo���͑S�Ď��s�����悤�ɕ]�������B
		def evaluate_target(name)

			@logger.debug(self.class){"Target evaluation start for [ #{name} ] @ [ #{@project.real_path} ]."}
			target=@project.find_target(name)
			raise AntHiveError.new("Target:[ #{name} ] was not found.") unless target
			
			# �J�n�^�O���L�^
			target_start(target)
			
			# depends �����̕]��
			target.depends.each{|dep|
				@logger.debug(self.class){"Target [ #{name} ] depends on [ #{dep} ].Process it first."}
				evaluate_target(dep)
			}

			# if�����Aunless������]�����������Ŏ��s�ۂ𔻒f���邽�߂̃t���O
			evaluate_this = true
			
			# if �����̕]��
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

			# unless �����̕]��
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

			# ���̎��_��evaluate_this �� true �̏ꍇ�̂�target�����̕]�����s���B
			if evaluate_this
				@logger.debug(self.class){"Evaluate target [ #{name} ] callings."}
				target.source.elements.each{|elm|
					evaluate_element(elm)
				}
			end
			
			# �I���^�O���L�^
			target_end(target)
			@logger.debug(self.class){"Target evaluation for [ #{name} ] end."}

			@steps
		end

		# Ant�X�N���v�g����1�v�f��]������B
		# ���ۂɂ́A���̃^�X�N�̎�ނɉ��������\�b�h���Ăяo���B
		#
		# [element] Ant�X�N���v�g����1�m�[�h��\������REXML::Element
		# [replacement] (����For�v�f�̂���)�ϊ��֌W������Hash�B��.{"@{rpkg}" => "test" }
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

		# ant�^�X�N��]������B
		#
		# [element] ant�^�X�N��\������REXML::Element
		# [replacement] (����For�v�f�̂���)�ϊ��֌W������Hash�B��.{"@{rpkg}" => "test" }
		def evaluate_ant(element,replacement={})
			next_file = element.attributes['antfile']
			next_file = 'build.xml' unless next_file
			next_file=replace_with(replacement,next_file)
			next_file=runtime_path(@table.expand(next_file)) # @root_dir + @basedir + @expand_basedir
			next_target=element.attributes['target']
			jump(next_file,next_target,element,replacement)
			@steps
		end

		# subant�^�X�N��]������B
		#
		# [element] subant�^�X�N��\������REXML::Element
		# [replacement] (����For�v�f�̂���)�ϊ��֌W������Hash�B��.{"@{rpkg}" => "test" }
		def evaluate_subant(element,replacement={})
			# subant �̏ꍇ�Abuild_path�Ńt�@�C�����𒼐ڎw�肷��ꍇ������΁A
			# path�����������ăt�@�C������antfile�Ŏw�肷�邱�Ƃ��o����(?)
			# �p�r�I�ɂ́A�O�҂̎g�p���@�̕������������悤�ȋC�����邯�ǂ悭����Ȃ��B
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

		# antcall�^�X�N��]������B
		#
		# [element] antcall�^�X�N��\������REXML::Element
		# [replacement] (����For�v�f�̂���)�ϊ��֌W������Hash�B��.{"@{rpkg}" => "test" }
		def evaluate_antcall(element,replacement={})
			next_file = @project.real_path # �������g
			next_target=element.attributes['target']
			jump(next_file,next_target,element,replacement,:without_toplevel)
			@steps
		end

		# antcall/ant/subant�^�X�N�̋��ʃ��\�b�h�B
		# "����"�t�@�C�����ƃ^�[�Q�b�g�����m�肵�Ă��邱�Ƃ�O��Ƃ��Ĉȉ��̏������s���B
		# - "���̃t�@�C��"������͂̏ꍇ�ɂ́Aparse���s���B
		# - "���̃v���p�e�B�\"�𐶐�����B(inheritAll�������U�̏ꍇ�ɂ͋�̃v���p�e�B�\�𐶐�)
		# - "���̃v���p�e�B�\"�ɁA�q�v�f�Ŏw�肳�ꂽproperty,param��o�^����B
		# - "���̃v���p�e�B�\"��p���āA"����Evaluater"�𐶐����āA���������s������B
		#
		# [next_file] "���̕]���Ώۃt�@�C��"������������B���̏����ɓn����鎞�_�œW�J�ς݂ł��邱�Ƃ����҂����B
		# [next_target] "���̕]���Ώۃ^�[�Q�b�g"������������B
		# [element] antcall/ant/subant�^�X�N��\������REXML::Element
		# [replacement] (����For�v�f�̂���)�ϊ��֌W������Hash�B��.{"@{rpkg}" => "test" }
		# [without_toplevel] �^��ݒ肵���ꍇ�ɂ́A�g�b�v���x���̉�͂��s��Ȃ�(antcall�p)�B�f�t�H���g��false�B
		def jump(next_file,next_target,element,replacement,without_toplevel=false)
			###############################################
			# next_file���܂�����͂̏ꍇ�ɂ͉�͂��s���B
			unless @hive.registed_map?(next_file)
				@logger.debug(self.class){"[ #{next_file} ] is not registered in hive.Requesting to controller for parse."}
				@controller.parse(RelativePath.between(@root_directory,next_file))
			else
				@logger.debug(self.class){"[ #{next_file} ] is already registered in Hive."}
			end

			###############################################
			# ����Evaluater�ɓn�����߂�PropertyTable������
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
			# ����Evaluater�𐶐����ď�����������B
			evaluater=Evaluater.new(@controller,@root_directory,next_file,next_table,@basedir)
			evaluater.without_toplevel_eval if without_toplevel

			steps=evaluater.evaluate(next_target)
			@steps+=steps
		end


		# for�v�f��]������B(�����Ant-Contrib�̒ǉ��^�X�N�ł�)
		# list�����̒l���擾���A������iterate���Ȃ���q�v�f�̕]�����s���B
		#
		# [element] for�v�f��\������REXML::Element
		# [replacement] (����For�v�f�̂���)�ϊ��֌W������Hash�B��.{"@{rpkg}" => "test" }
		def evaluate_for(element,replacement={})
			list=element.attributes['list']
			if list
				list=@table.expand(list)
			else
				# list���������݂��Ȃ��P�[�X�͖�����
				@logger.warn(self.class){"For node NOT have 'list' attribute. Evaluating 'for' may be unstable."}
				element.elements.each{|elm|
					evaluate_element(elm)
				}
				return
			end

			param=element.attributes['param']
			# param���������݂��Ȃ��P�[�X�͗�O
			AntHiveError.new("For node does not have 'param' (Required) attribute.") unless param

			delmiter=element.attributes['delimiter']
			delimiter=','unless delimiter

			list.split(delimiter).each{|entry|
				element.elements.each{|elm|
					evaluate_element(elm,replacement.merge({"@{#{param}}"=>entry}))
				}
			}
		end

		# propertycopy�v�f��]������B(�����Ant-Contrib�̒ǉ��^�X�N�ł�)
		# property����(����name����)�̃v���p�e�B���Afrom�����̕����������v���p�e�B�l�Őݒ肷��B
		#
		# [element] propertycopy�v�f��\������REXML::Element
		# [replacement] (����For�v�f�̂���)�ϊ��֌W������Hash�B��.{"@{rpkg}" => "test" }
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

		# available�v�f��]������B
		# [ asis? ]�����Ƃ���file���������v�f�̂ݎ��ۂ̕]�������{����B
		# condition�v�f�̃l�X�g�����q�v�f�̏ꍇ������̂ŁAproperty�������w�肳��Ă��Ȃ��ꍇ�ɂ́A�����𖳎�����B
		#
		# [element] available�v�f��\������REXML::Element
		# [replacement] (����For�v�f�̂���)�ϊ��֌W������Hash�B��.{"@{rpkg}" => "test" }
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

		# var�v�f��]������B(�����Ant-Contrib�̒ǉ��^�X�N�ł�)
		# ���ۂɂ͑S�Ă̏�����evaluate_property�ɔC���Ă��܂��蔲�������B
		#
		# [element] propertycopy�v�f��\������REXML::Element
		# [replacement] (����For�v�f�̂���)�ϊ��֌W������Hash�B��.{"@{rpkg}" => "test" }
		def evaluate_var(element,replacement={})
			evaluate_property(element,replacement,true) # mutable=true(��)�Ƃ���property�̏������Ƃ����B
		end

		# property�v�f��]������B
		# �T�|�[�g���Ă��鑮���͈ȉ��̂Ƃ���B
		# - file=''
		# - name='' and value=''
		#
		# [element] available�v�f��\������REXML::Element
		# [replacement] (����For�v�f�̂���)�ϊ��֌W������Hash�B��.{"@{rpkg}" => "test" }
		# [mutable] �f�t�H���g��false(�s��)�B�{���Aproperty�͕s�ςȂ̂����Aevaluate_var�Ǝ��������L���邽�߂Ɏg�p
		# [alternate_table] ��փv���p�e�B�\��p���邩�ۂ��B�^�̏ꍇ�́A��փv���p�e�B�\�ɑ΂��ăv���p�e�B��o�^����B�f�t�H���g��false(��փv���p�e�B�\��p�����A@table���g�p)�B
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
				# ���s���ł͂Ȃ��̂łƂ肠�����ǂ����悤���Ȃ����B

			# other property tasks
			else
				@logger.error(self.class){"NOT IMPLEMENTED #{word.upcase} ATTRIBUTE."}
			end
		end

		# ���s���̃R���e�L�X�g������������ł̃t�@�C���p�X��ԋp����B
		# ��̓I�ɂ͈ȉ��̔��f���s���B
		# - �w�肳�ꂽfile����΃p�X�\�L�̏ꍇ�ɂ́Afile�擪��/������������ŁA���z���[�g����_�Ƃ������΃p�X���\�z
		# - �w�肳�ꂽfile�����΃p�X�\�L�̏ꍇ�ɂ́A���g�����������ꂽ�ۂ�@basedir+@expand_basedir+file���A���z���[�g����_�Ƃ������΃p�X�ŕ\��
		# - ��L��"���z���[�g����̑��΃p�X"���A���ۂɑ��݂���Ȃ�΂��̒l���B���ۂɂ͑��݂��Ȃ��Ȃ�΁A�x�����グ����œK���ȃp�X��ԋp�B
		#
		# [file] 
		def runtime_path(file)
			raise AntHiveError.new("@root_directory is not set.") unless @root_directory
			raise AntHiveError.new("@basedir is not set.") unless @basedir

			# �w�肳�ꂽfile����΃p�X�w��̏ꍇ�ɂ́A�擪��@root_directory�݂̂��Z�b�g���ĕԋp
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

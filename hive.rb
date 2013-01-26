#!ruby -Ks

module AntHive
	
	#��͍ς݂�Ant�X�N���v�g�̏W�Ϗ�
	class Hive

		# 1�{�̌o�H��\������N���X
		# ���̂́AEvaluatedStep�̔z��(@route)�𒆐S�Ƃ��āA
		# �o�H�J�n���̏��Ƃ��Ẵt�@�C�����ƊJ�n�^�[�Q�b�g���𑮐��Ƃ��Ď���
		class Route
			def initialize(file,entry_point,options,route)
				@file=file
				@entry_point=entry_point
				@options=options
				@route=route
			end
			attr_reader :file, :entry_point, :options, :route

			#�����@options�Ɠ����options���w�肳�ꂽ�Ȃ�ΐ^
			#
			#[options] ���I�o�H�]���J�n���̃v���p�e�B���˒l��Hash
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

			#�]���ς݌o�H���(@route == [ EvaluatedStep, ...])��ԋp����B
			def to_a; @route.dup; end

			#�]���ς݌o�H���(@route == [ EvaluatedStep, ...])��yield����B
			def each; @route.each{|step| yield step}; end

			def to_s
				"#{@entry_point}@#{File.basename(file,'.xml')}("+@options.collect{|k,v| "#{k}=#{v}"}.join(',') +")"
			end
		end

		# ���������s���B
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

		# route�̈ꗗ��ԋp����B
		def route_entries
			@routes.collect{|r| r.to_s }.sort
		end

		#�w�肳�ꂽroute�̏���ԋp����B
		#
		#[file] ���I�o�H�]���Ώۃt�@�C����(ant-hive��������\�Ȏ��ۂ̃t�@�C���p�X�B���z���[�g����̃p�X�ł͂Ȃ��B)
		#[entry_point] ���I�o�H�]���Ώۂ̎n�_�^�[�Q�b�g��(nil�͕s��)
		#[options] ���I�o�H�]�������{�����ۂ̃v���p�e�B���˒l��Hash
		def routes(file,entry_point,options)
			@logger.warn(self.class){"Requested route (File:[ #{file} ] EntryPoint:[ #{entry_point} ]) is not set."} unless registed_route?(file,entry_point,options)
			@routes.find_all{|r| r.file==file && r.entry_point==entry_point && r.same_option?(options)}.first
		end

		#�w�肳�ꂽroute��񂪖��o�^�Ȃ�΁AHive�ɓo�^����B
		#
		#[file] ���I�o�H�]���Ώۃt�@�C����(ant-hive��������\�Ȏ��ۂ̃t�@�C���p�X�B���z���[�g����̃p�X�ł͂Ȃ��B)
		#[entry_point] ���I�o�H�]���Ώۂ̎n�_�^�[�Q�b�g��(nil�͕s��)
		#[options] ���I�o�H�]�������{�����ۂ̃v���p�e�B���˒l��Hash
		#[route] �o�H�]�����ʂ�\������EvaluatedStep�̔z��
		def regist_route(file,entry_point,options,route)
			@routes.push(Route.new(file,entry_point,options,route)) unless registed_route?(file,entry_point,options)
		end

		#�w�肳�ꂽroute���o�^����Ă���ꍇ�ɂ͐^�A���o�^�̏ꍇ�ɂ͋U��ԋp����B
		#
		#[file] ���I�o�H�]���Ώۃt�@�C����(ant-hive��������\�Ȏ��ۂ̃t�@�C���p�X�B���z���[�g����̃p�X�ł͂Ȃ��B)
		#[entry_point] ���I�o�H�]���Ώۂ̎n�_�^�[�Q�b�g��(nil�͕s��)
		#[options] ���I�o�H�]�������{�����ۂ̃v���p�e�B���˒l��Hash
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

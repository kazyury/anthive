#!ruby -Ks

module AntHive
	
	# �v���p�e�B���Ǘ�����N���X�B
	# ���̂�Hash(@table)�����A�L�[�l�̏d������A�l�̍ċA�W�J����������B
	class PropertyTable

		# �������������s���B
		#
		# @table :: �v���p�e�B�\(var���܂�)�B�v���p�e�B���˃v���p�e�B�l��Hash�B
		# @immutables :: �s�σv���p�e�B���̔z��
		def initialize()
			@logger=SingletonLogger.instance()
			@table={} # @table�́A�V���v����String=>String�̃n�b�V���B
			@immutables=[]
			@logger.debug(self.class){"#{self.class} initiated."}
		end
		attr_accessor :table, :immutables

		# �v���p�e�B�e�[�u����key��val���i�[����B
		# key��val�͂��ꂼ��String�łȂ���΂Ȃ�Ȃ��B
		#
		# �i�[���悤�Ƃ���key���ύX�s�\(mutable:false)�Ŋ��ɓo�^����Ă���ꍇ�ɂ́A
		# �X�V�����͍s��Ȃ��B(debug���O�̂ݏo�́Bant�̏����ł͊��ɓo�^����Ă�����͏㏑������Ȃ��������҂��āA
		# ���x�������L�[��o�^���悤�Ƃ��鏈�����������߁A���O�������Ƃ������̂ŁB)
		#
		# key :: �v���p�e�B��������������
		# val :: �v���p�e�B�l������������(${}���܂܂�Ă��Ă��\��Ȃ�)
		# mutable :: �f�t�H���g��false�B
		#            false�̏ꍇ�ɂ́A��U�v���p�e�B�\�ɓo�^���ꂽ�v���p�e�B�l�ɂ��ẮA���e���X�V���鎖���o���Ȃ��B
		#            true�̏ꍇ�ɂ́A�v���p�e�B�\�ɓo�^���ꂽ�l����������邱�Ƃ�����(��ɁAAnt-Contrib <var>�^�X�N�̂���)�B
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

		# key���v���p�e�B�e�[�u���ɓo�^����Ă��邩�B
		# - �o�^����Ă���ꍇ�Atrue
		# - �o�^����Ă��Ȃ��ꍇ�Afalse
		#
		# key :: �v���p�e�B��������������
		def registed?(key)
			@table[key] ? true : false
		end

		# key�ɑΉ�����l���擾����B�f�t�H���g(expansion=true)�ł͉\�Ȕ͈͂œW�J�����l��ԋp����B
		# �Ή�����L�[���o�^����Ă��Ȃ��ꍇ�ɂ͗�OAntHiveError�𔭐�������B
		#
		# key :: �v���p�e�B��������������
		# expansion :: �f�t�H���g��true�B
		#              true�̏ꍇ�ɂ́A�v���p�e�B���ɑΉ�����v���p�e�B�l��W�J���ĕԋp����B
		#              false�̏ꍇ�ɂ́A�v���p�e�B���ɑΉ�����v���p�e�B�l�����̂܂ܕԋp����B
		def value_for(key,expansion=true)
			raise AntHiveError.new("Key:[ #{key} ] is not registed.") unless registed?(key)
			if expansion
				self.expand(@table[key])
			else
				@table[key]
			end
		end
		
		# ������val������̃v���p�e�B�\��p���ēW�J�����l��ԋp����B
		# �W�J�́A${...}�̃p�^���Ƀ}�b�`����...�������v���p�e�B�\�̃L�[�ƌ��Ȃ��A����ɑΉ�����v���p�e�B�l�̒l�ŕϊ����邱�Ƃōs���B
		# �W�J�������ʂ��X�ɓW�J�\�ł���ꍇ�ɂ́A�W�J�������s��(�ċA)
		#  ��. 
		#    srv  => foo
		#    name => ${srv}.co.jp
		#    url  => http://${name}
		#
		#    expand('http://${name}') #=> http://foo.co.jp
		#
		# ${}���̂��l�X�g���Ă��\��Ȃ�
		#  ��. 
		#    srv  => foo
		#    foo => 127.0.0.1
		#
		#    expand('${${srv}}') #=> 127.0.0.1
		#
		# str :: �W�J���s��������
		def expand(str)
			raise AntHiveError.new("[ #{str} ] is not String but [ #{str.class} ].") unless str.is_a?(String)
			@logger.debug(self.class){"expanding [ #{str} ]."}

			# expandable?�łȂ���΁A���̒l�����̂܂ܕԋp
			return str unless expandable?(str)

			re_scan=false
			# expandables �̂��ꂼ��ɂ��ď������s���B
			#
			expandables(str).each do |chunk|
				@logger.debug(self.class){"Check for chunk:[ #{chunk} ]."}

				replace_pattern=Regexp.new(Regexp.escape('${'+chunk+'}'))
				replace_string=@table[chunk]
				
				if replace_string	#@table�Ɍ��������ꍇ
					@logger.debug(self.class){"Value found for chunk:[ #{chunk} ]."}
					@logger.debug(self.class){"Using [ #{replace_string} ] for [ #{replace_pattern} ], expand [ #{str} ]."}

					# �����ϊ��h�~
					if replace_string[2..-2] == chunk
					else
						re_scan=true
						str.gsub!(replace_pattern,replace_string)
					end
				
				else	#@table�Ɍ�����Ȃ��ꍇ
					@logger.debug(self.class){"Tended to expand [ #{chunk} ] ,but none in property table."}
				end
			end
			
			# �W�J���ʂ��X�ɓW�J�\�Ȃ�΍ċA�I�ɏ������s��
			expand(str) if expandable?(str) && re_scan == true

			str
		end

		# ���������񂪓W�J�\���ۂ���true����false�ɂĕԋp����B
		#
		# str :: �W�J���̕�����
		def expandable?(str)
			expandables(str).size == 0 ? false : true
		end

		# �����������W�J�\��chunk�ɕ�������chunk�̔z��Ƃ��ĕԋp����B
		# chunk�������${}�̒��g�̕����݂̂�ԋp����B(���g��${,}���܂܂�Ă�����A���ʒl�Ɋ܂܂��)
		# �W�J�\�ȕ����񂪑��݂��Ȃ���΁A���ʒl��size��0�ƂȂ�B
		#
		#  ��
		#    expandables('${dir1}/${dir2}/${dir3}') #=> %w(dir1 dir2 dir3)
		#    expandables('/home/kz') #=> %w()
		#    expandables('${�{����${weather}�Ȃ�}') #=> %w(weather)
		#
		# str :: �W�J���̕�����
		def expandables(str)

			# 1�������Ƃɕ������ď���
			#
			# - process_1 :: $�����������ꍇ��ON,$�����{������������OFF
			# - process_2 :: $�����{������������ON,}��OFF
			# - buffer :: process_2��ON�̎��́A�����i�[�̈�
			# - result :: }�Ŋm�肵��������̊i�[�̈�
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
		#����̎����ł́Aant�ďo�̍ۂ�PropertyTable��(�[��)������n�����߂Ɉȉ��̃��\�b�h���`���Ă��邪�A���Ȃ肢�������Ȃ��B

		# Evaluater��ant�ďo��]������ۂ�PropertyTable��(�[��)������n�����߂ɒ�`
		# ����̕������쐬���ĕԋp����B
		# �����̃v���p�e�B�e�[�u���ɂ��ẮA����̃v���p�e�B�e�[�u���̐[��������Marshal��p���č쐬���Ă���B
		def deep_copy
			new_one=self.class.new()
			new_one.table=Marshal.load(Marshal.dump(@table))
			new_one.immutables=@immutables
			new_one
		end
		
	end
end

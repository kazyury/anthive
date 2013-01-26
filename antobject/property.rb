#!ruby -Ks

module AntHive
	module AntObject
		# property�^�X�N��\������N���X
		# �������A�ڍ׏��́A@source(REXML::Element)�̌`�ŕێ������܂܂ł���A
		# �C���X�^���X�̏�ԂƂ��ẮA�T�}���I�Ȉȉ��̏���ێ�����̂݁B
		# - name   :Property��name���� �̒l(value�Ƒ�)
		# - value  :Property��value���� �̒l(name�Ƒ�)
		# - environment :Property��environment���� �̒l
		# - file   :Property��file���� �̒l
		class Property
			def initialize(src)
				@source=src
				@file=nil
				@environment=nil
				@name=nil
				@value=nil
			end
			attr_accessor :file, :environment, :name, :value
			attr_reader :source
		end
	end
end

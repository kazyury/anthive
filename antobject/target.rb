#!ruby -Ks

module AntHive
	module AntObject
		# Ant��1�^�[�Q�b�g��\������N���X�B
		# �������A�ڍ׏��́A@source(REXML::Element)�̌`�ŕێ������܂܂ł���A
		# �C���X�^���X�̏�ԂƂ��ẮA�T�}���I�Ȉȉ��̏���ێ�����̂݁B
		# - name   :target��name���� �̒l
		# - if     :���̃^�[�Q�b�g��if���������ꍇ�ɂ́A���̑����l(�w��Ȃ��̏ꍇ�ɂ�nil�̂܂�)
		# - unless :���̃^�[�Q�b�g��unless���������ꍇ�ɂ́A���̑����l(�w��Ȃ��̏ꍇ�ɂ�nil�̂܂�)
		# - depends:���̃^�[�Q�b�g��depends���������ꍇ�ɂ́A���̑����l�̔z��(�w��Ȃ��̏ꍇ�ɂ�empty�̂܂�)
		# - calls  :���̃^�[�Q�b�g��������antcall, ant, subant�^�X�N�����ꍇ�ɂ́A���̏��̔z��B(�Ȃ��̏ꍇ�ɂ�empty�̂܂�)
		# - description  :���̃^�[�Q�b�g��description���������ꍇ�ɂ́A���̑����l(�w��Ȃ��̏ꍇ�ɂ�nil�̂܂�)
		class Target
			# ���������s���B
			# - src : ����target�^�O��\������REXML::Element
			def initialize(src)
				@source=src
				@name=nil
				@if=nil
				@unless=nil
				@depends=[]
				@calls=[]
				@description=""
			end
			attr_accessor :name, :if, :unless, :calls
			attr_reader :source, :depends
			attr_writer :description

			def depends=(list); @depends=list.split(','); end
			def description; @description.tosjis; end

			def to_s; @name; end
		end
	end
end

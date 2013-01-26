#!ruby -Ks

module AntHive
	module AntObject

		#Ant��1�v���W�F�N�g��\������N���X�B
		#�������A����ł͕����t�@�C����1�̃v���W�F�N�g���\������ꍇ�͍l������Ă��Ȃ����߁A
		#������A"1 xml = 1 AntObject::Project" �ƂȂ��Ă���B
		#����ł͂قڒP�Ȃ�\����
		class Project
			
			#�������������s���B
			#- real_path : ���ۂɉ����\�ȃt�@�C���p�X
			def initialize(real_path)
				@real_path=real_path
				@name=nil
				@basedir=nil
				@default=nil
				@all_nodes=[]
			end
			attr_accessor :name, :basedir, :default
			attr_reader :real_path, :all_nodes

			#�q�m�[�h��ǉ�����B
			#- child : REXML::Element
			def append(child)
				@all_nodes.push child
			end

			#�o�^����Ă���S�^�[�Q�b�g�ɂ��ẴC�e���[�^
			def each_target(&b)
				self.targets().each{|target| yield target }
			end

			#����Project�ɓo�^����Ă���Target�̂����Aname�Ɠ��������O������Target��1�̂ݕԋp����B
			#- name : ��������^�[�Q�b�g���̕�����(��. "publish" )
			def find_target(name)
				@all_nodes.find{|node| node.is_a?(Target) && node.name == name}
			end

			#����Project�ɓo�^����Ă���S�Ă�Target�̔z���ԋp����B
			def targets
				@all_nodes.find_all{|node| node.is_a?(Target)}
			end
		end
	end
end

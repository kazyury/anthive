#!ruby -Ks

module PropertyFile

	# �v���p�e�B�t�@�C����ǂݍ��݁A����key��value��ԋp����B
	# �u���b�N���^�����Ă���ꍇ�ɂ́A�e�X��yield����B
	# - input
	#   [file] �ǂݍ��ރv���p�e�B�t�@�C�����B���݂��Ȃ��t�@�C���̏ꍇ�ɂ�RuntimeError��raise
	# - output
	#   [key] �v���p�e�B�t�@�C�����Œ�`����Ă���v���p�e�B���B������
	#   [val] �v���p�e�B���ɑΉ������l�B
	#         �J���}(,)��؂�ŕ����G���g����(�󔒂͕s��)�B
	#         �G�X�P�[�v���ꂽ���s�ɂ�蕡���s�ɓn��ꍇ�ɂ��Ή�����B
	def self.read_property(file,&b)
		raise RuntimeError.new("Requested file [ #{file} ] was not found.") unless File.file?(file)
		buffer={}
		contents=File.read(file)

		# �R�����g(#�ȍ~���s�����܂�)���폜����B
		# �A������󔒂�1�̋󔒂ɒu������B(���s�����͉��s�����̂܂܂�)
		contents.gsub!(/#.*?$/,'') 
		contents.gsub!(/\t/,' ')
		contents.gsub!(/\n{2,}/,"\n")
		contents.gsub!(/\t{2,}/," ")
		contents.gsub!(/ {2,}/," ")
		
		#	�󔒍s����������B
		contents=contents.split("\n").collect{|line| line.strip }.delete_if{|line| line=='' }.join("\n")

		# �G�X�P�[�v���ꂽ���s�������󕶎��ɕϊ�����B
		contents.gsub!(/\\\n/,'')

		#	�e�s�ɂ���
		#	 '='���܂܂�Ă��Ȃ��ꍇ�ɂ͗�O
		#	 '=' �̌�낪�󔒕����݂̂̏ꍇ�ɂ�warn
		contents.split("\n").each{|line|
			raise RuntimeError.new("In [ #{file} ], line without '=' appears. at [ #{line} ].") unless line.include?('=')

			line.strip!
			key,val=line.split('=')

			# ���ꂼ��̋󔒂�����
			# '='�̌�ɕ��������݂��Ȃ��ꍇ�ɂ͌x����\��(-v�t����ruby�N�����̂�)���Aval���󕶎��ɐݒ肷��B
			key.strip!
			if val
				val.strip!
			else
				val=''
			end
			buffer[key]=val
			yield key,val if block_given?
		}
		buffer
	end

	def self.properties(file,&b); PropertyFile.read_property(file,&b); end
	def read_property(file,&b); PropertyFile.read_property(file,&b); end

	alias :properties :read_property

end



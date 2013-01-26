#!ruby -Ks

module PropertyFile

	# プロパティファイルを読み込み、そのkeyとvalueを返却する。
	# ブロックが与えられている場合には、各々をyieldする。
	# - input
	#   [file] 読み込むプロパティファイル名。存在しないファイルの場合にはRuntimeErrorをraise
	# - output
	#   [key] プロパティファイル内で定義されているプロパティ名。文字列
	#   [val] プロパティ名に対応した値。
	#         カンマ(,)区切りで複数エントリ化(空白は不可)。
	#         エスケープされた改行により複数行に渡る場合にも対応する。
	def self.read_property(file,&b)
		raise RuntimeError.new("Requested file [ #{file} ] was not found.") unless File.file?(file)
		buffer={}
		contents=File.read(file)

		# コメント(#以降改行文字まで)を削除する。
		# 連続する空白を1つの空白に置換する。(改行文字は改行文字のままで)
		contents.gsub!(/#.*?$/,'') 
		contents.gsub!(/\t/,' ')
		contents.gsub!(/\n{2,}/,"\n")
		contents.gsub!(/\t{2,}/," ")
		contents.gsub!(/ {2,}/," ")
		
		#	空白行を除去する。
		contents=contents.split("\n").collect{|line| line.strip }.delete_if{|line| line=='' }.join("\n")

		# エスケープされた改行文字を空文字に変換する。
		contents.gsub!(/\\\n/,'')

		#	各行について
		#	 '='が含まれていない場合には例外
		#	 '=' の後ろが空白文字のみの場合にはwarn
		contents.split("\n").each{|line|
			raise RuntimeError.new("In [ #{file} ], line without '=' appears. at [ #{line} ].") unless line.include?('=')

			line.strip!
			key,val=line.split('=')

			# それぞれの空白を除去
			# '='の後に文字が存在しない場合には警告を表示(-v付きでruby起動時のみ)し、valを空文字に設定する。
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



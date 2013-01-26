#!ruby -Ks

module AntHive
	module AntObject
		# Antの1ターゲットを表現するクラス。
		# ただし、詳細情報は、@source(REXML::Element)の形で保持したままであり、
		# インスタンスの状態としては、サマリ的な以下の情報を保持するのみ。
		# - name   :targetのname属性 の値
		# - if     :このターゲットがif属性を持つ場合には、その属性値(指定なしの場合にはnilのまま)
		# - unless :このターゲットがunless属性を持つ場合には、その属性値(指定なしの場合にはnilのまま)
		# - depends:このターゲットがdepends属性を持つ場合には、その属性値の配列(指定なしの場合にはemptyのまま)
		# - calls  :このターゲットが内部でantcall, ant, subantタスクを持つ場合には、その情報の配列。(なしの場合にはemptyのまま)
		# - description  :このターゲットがdescription属性を持つ場合には、その属性値(指定なしの場合にはnilのまま)
		class Target
			# 初期化を行う。
			# - src : このtargetタグを表現するREXML::Element
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

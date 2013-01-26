#!ruby -Ks

module AntHive
	module AntObject
		# propertyタスクを表現するクラス
		# ただし、詳細情報は、@source(REXML::Element)の形で保持したままであり、
		# インスタンスの状態としては、サマリ的な以下の情報を保持するのみ。
		# - name   :Propertyのname属性 の値(valueと対)
		# - value  :Propertyのvalue属性 の値(nameと対)
		# - environment :Propertyのenvironment属性 の値
		# - file   :Propertyのfile属性 の値
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

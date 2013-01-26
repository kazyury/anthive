#!ruby -Ks

module AntHive
	module AntObject

		#Antの1プロジェクトを表現するクラス。
		#ただし、現状では複数ファイルで1つのプロジェクトを構成する場合は考慮されていないため、
		#実効上、"1 xml = 1 AntObject::Project" となっている。
		#現状ではほぼ単なる構造体
		class Project
			
			#初期化処理を行う。
			#- real_path : 実際に解決可能なファイルパス
			def initialize(real_path)
				@real_path=real_path
				@name=nil
				@basedir=nil
				@default=nil
				@all_nodes=[]
			end
			attr_accessor :name, :basedir, :default
			attr_reader :real_path, :all_nodes

			#子ノードを追加する。
			#- child : REXML::Element
			def append(child)
				@all_nodes.push child
			end

			#登録されている全ターゲットについてのイテレータ
			def each_target(&b)
				self.targets().each{|target| yield target }
			end

			#このProjectに登録されているTargetのうち、nameと等しい名前を持つTargetを1つのみ返却する。
			#- name : 検索するターゲット名の文字列(例. "publish" )
			def find_target(name)
				@all_nodes.find{|node| node.is_a?(Target) && node.name == name}
			end

			#このProjectに登録されている全てのTargetの配列を返却する。
			def targets
				@all_nodes.find_all{|node| node.is_a?(Target)}
			end
		end
	end
end

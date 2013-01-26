#!ruby -Ks

module AntHive
	module AntObject
		class AnonNode
			def initialize(path)
				@path=path
				@task=nil
				@attributes={}
			end
			attr_accessor :path, :task, :attributes

		end
	end
end

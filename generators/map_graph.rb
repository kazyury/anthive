#!ruby -Ks

require 'erb'

module AntHive
	class MapGraphGenerator
		def initialize(hive)
			@logger=SingletonLogger.instance()
			@root_directory=nil
			@hive=hive
			@clusters={}
			@edges=[]
			@logger.debug(self.class){"#{self.class} initiated."}
		end
		attr_accessor :root_directory

		#== generate
		#指定されたファイルのAntObject::Projectを取得し、
		#静的解析mapとしてgraphvizを用いてsvg出力を行う。
		def generate(real_path)
			if project=@hive.maps[real_path] #=> AntHive::AntObject::Project
				@logger.debug(self.class){"For requested map( #{real_path} ), got [ #{project} ] map info."}

				# ProjectからTargetの一覧を取得
				# それぞれのTargetについて、depends属性, calls属性を取得
				project.targets.each{|target|

					# targetのクラスタへの追加
					append_graphviz_node(real_path, target.name)

					# 依存関係によるEdgeの追加
					unless target.depends.empty?
						target.depends.each{|dep| append_graphviz_edge(real_path, dep, real_path, target.name,:depends) }
					end

					unless target.calls.empty?
						target.calls.each{|cal|
							type=cal[0]
							path_to=cal[1]
							target_to=cal[2]
							begin
								path_to=RealPath.realpath(@root_directory,path_to)
							rescue AntHiveError=>e
								@logger.debug(self.class){"During antcalling process of [ #{target} ]@[ #{real_path} ], path:[ #{path_to} ] could not solved."}
								path_to = yield path_to
								@logger.debug(self.class){"path was solved as [ #{path_to} ]."}
							end
							
							unless target_to
								if next_project = @hive.maps[path_to]
									target_to = next_project.default
								else
									target_to = '*** DEFAULT ***'
								end
							end

							path_to = '*** AnonAnt ***' unless path_to
							append_graphviz_edge(real_path, target.name, path_to, target_to, type)
						}
					end
				}
			else
				@logger.warn(self.class){"For requested map( #{real_path} ), map did NOT FOUND."}
			end
		end

		def graph(fake)
			out_dot_file=@root_directory+'.dot'
			out_svg_file=@root_directory+'.svg'
			template=ERB.new(File.read('./generators/map.erb'))

			unless fake
				File.open(out_dot_file,'w'){|f| f.puts template.result(binding) }

				@logger.debug(self.class){"converting [ #{out_dot_file} ] into [ #{out_svg_file} ]. "}
				system("dot -Tsvg #{out_dot_file} -o #{out_svg_file}")
				@logger.error(self.class){"may not installed graphviz ? converting #{out_dot_file} was failed. "} unless $?==0
			end
			out_svg_file
		end


		private
		def append_graphviz_node(real_path, target)
			@logger.debug(self.class){"Appending graphviz target node:[ #{target} ] for cluster:[ #{real_path} ]."}
			if targets=@clusters[real_path]
				targets.push target
			else
				@clusters[real_path]=[target]
			end
		end

		def append_graphviz_edge(real_path_from, target_from, real_path_to, target_to,type)
			@logger.debug(self.class){"Appending graphviz edge(type:[ #{type} ]) from node:[ #{target_from} ]@[ #{real_path_from} ] to [ #{target_to} ]@[ #{real_path_to} ]."}
			@edges.push [real_path_from, target_from, real_path_to, target_to,type]
		end

		def write_cluster(cluster,nodes)
			result ="subgraph cluster_#{normalize_filename(cluster)} {\n"
			result+="  label = \"#{cluster}\"\n"
			nodes.each{|node| result+="  \"#{node}_at_#{normalize_filename(cluster)}\" [ label=\"#{node}\" ]\n" }
			result+="}"
			result
		end

		def write_edges
			result=[]
			@edges.each{|edge|
				from_cluster=normalize_filename(edge[0])
				from_target=edge[1]
				to_cluster=normalize_filename(edge[2])
				to_target=edge[3]
				type = edge[4]
				case type
				when :depends
					style='[ style="dashed" ]'
				when :antcall
					style='[ style="solid" ]'
				when :ant
					style='[ style="solid" arrowhead="odiamond"]'
				when :subant
					style='[ style="solid" arrowhead="oldiamond"]'
				else
					raise AntHiveError.new("Unsupported type [ #{type} ].")
				end
				result.push "\"#{from_target}_at_#{from_cluster}\" -> \"#{to_target}_at_#{to_cluster}\" #{style}"
			}
			result.join("\n")
		end

		def normalize_filename(name)
			name=name.split('/').collect{|word| word.capitalize! }.join('')
			name.gsub!('-','')
			File.basename(name,'.xml')
		end

	end
end

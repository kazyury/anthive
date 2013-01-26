#!ruby -Ks

module AntHive
	#Antスクリプトの解析を行い AntObject::Project ( AntObject::Target , AntObject::Property を内包する)
	#を生成・返却する。
	class Parser
		def initialize()
			@logger=SingletonLogger.instance()
			@root_directory=nil
			@logger.debug(self.class){"#{self.class} initiated."}
		end
		attr_reader :root_directory

		#仮想のルートディレクトリを設定する。
		#指定されるディレクトリは存在しなければならない。
		#また、末尾が/の場合には削除する。
		#- root_dir : 仮想のルートディレクトリを示す文字列
		def root_directory=(root_dir)
			raise AntHiveError.new("Directory:[ #{root_dir} ] does not exist.") unless File.directory?(root_dir)

			root_dir.chop!  while /\/\Z/=~root_dir #末尾が/の場合は削除する。
			@root_directory=root_dir
			@logger.debug(self.class){"@root_directory was set to [ #{@root_directory} ]."}
		end

		#指定されたファイルの解析を開始する。 
		#
		#Parser#parseが呼ばれた段階で、新たなAntObject::Projectが生成される。
		#この生成されたAntObject::Projectは、このparse処理の実行経路内にローカルであり、
		#別途Parser#parseされた際に生成されるAntObject::Projectとは独立している。
		#
		#- real_path : 実際に解決可能なファイルパス
		def parse(real_path)
			raise AntHiveError.new("Use #{self.class}#root_directory=() before parse.") unless @root_directory
			raise AntHiveError.new("Ant script file [ #{real_path} ] does not exist.") unless File.file?(real_path)

			project=AntObject::Project.new(real_path)
			root_element=REXML::Document.new(File.new(real_path)).root

			raise AntHiveError.new("Is this an Ant file? Root node is not 'project' but was [ #{root_element.name} ].") unless root_element.name == 'project'

			@logger.debug(self.class){"Parsing top-level definitions."}
			parse_project(root_element,project)

			@logger.debug(self.class){"Parsing targets and properties(first children) definitions."}
			parse_children(root_element,project,real_path)
			project
		end


		private
		#--------------------------------------------------------------------
		def parse_project(root,project)
			root.attributes.each{|key,val|
				case key
				when 'name';   project.name=val
				when 'basedir';project.basedir=val
				when 'default';project.default=val
				else
					raise AntHiveError.new("Is this an Ant file? Root node has attribute named [ #{key} ].")
				end
			}
		end

		def parse_children(root,project,real_path)
			root.elements.each{|node|
				case node.name
				##############################################################
				when 'property'
					prop=AntObject::Property.new(node)
					node.attributes.each{|key,val|
						case key
						when 'file' ; prop.file=val
						when 'environment' ; prop.environment=val
						when 'name' ; prop.name=val
						when 'value' ; prop.value=val
						else
							raise AntHiveError.new("Not Implemented [ AntObject::Property##{key}= ]")
						end
					}
					project.append prop
				##############################################################
				when 'target'
					target=AntObject::Target.new(node)
					node.attributes.each{|key,val|
						case key
						when 'name';    target.name=val
						when 'if';      target.if=val
						when 'unless';  target.unless=val
						when 'depends'; target.depends=val
						when 'description'; target.description=val
						else
							raise AntHiveError.new("Not Implemented [ AntObject::Target##{key}= ]")
						end
					}
					stack=[]
					stack=search_calls(node,real_path,stack)
					target.calls=stack
					project.append target
				##############################################################
				when 'taskdef', 'path'
					anon=AntObject::AnonNode.new(node)
					anon.task=node.name
					node.attributes.each{|key,val| anon.attributes[key]=val }
				else
					raise AntHiveError.new("Not Implemented [ AntObject::#{node.name.capitalize} ]")
				end
			}
		end

		def search_calls(node,real_path,stack=[])
			node.elements.each{|elm|
				if elm.has_elements?
					search_calls(elm,real_path,stack)
				end
				case elm.name
				when 'ant'
					next_file=elm.attributes['antfile']
					next_file='build.xml' unless next_file
					stack.push [:ant, next_file, elm.attributes['target']]
				when 'antcall'
					next_file=RelativePath.between(@root_directory,real_path)
					stack.push [:antcall, next_file, elm.attributes['target']]
				when 'subant'
					ant_file=elm.attributes['antfile']
					build_path= elm.attributes['buildpath']

					if ant_file && build_path
						next_file = build_path+"/"+ant_file
					elsif ant_file
						next_file = ant_file
					elsif build_path
						if File.file?(build_path)
							next_file = build_path
						elsif File.directory?(build_path)
							next_file = build_path +'/build.xml'
						else
							next_file = build_path
						end
					else
						next_file = 'build.xml'
					end

					stack.push [:subant, next_file, elm.attributes['target']]
				else
				end
			}
			return stack
		end
	end
end

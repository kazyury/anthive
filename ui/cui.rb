#!ruby -Ks

module AntHive
	#= CUI
	#�R�}���h���C���̃��[�U�C���^�t�F�[�X��񋟂���B
	#�Ƃ͂����Ă��A�R�}���h���C���I�v�V�����̉�͂͑O�i�K�ōς�ł���̂ŁA
	#��̓I�ɂ͈ȉ��̋@�\�݂̂��������A�c���Controller�ɂ��C�����Ă���B
	#- �R�}���h���C��������Logger�̒�`
	#- �኱�̃��[�U�Ƃ̑Θb�@�\
	#- �\���t�@�C�����(�w�肳�ꂽ�ꍇ�̂�)
	class CUI
		def initialize(loglevel,fake=false)
			@logger=SingletonLogger.instance()
			@logger.level=loglevel
			@logger.info(self.class){"ant-hive is starting. Log level is [ #{@logger.level} ]."}
			@controller=Controller.new(fake)
			@controller.ui=self
		end

		def ask(statement)
			statement.split("\n").each{|stm| tell(stm)}
			print "[ AntHive needs answer ]---> "
			answer = gets.chomp.strip
			answer
		end

		def tell(statement)
			puts "[ AntHive Message ]:"+statement
		end

		def root_directory=(root_dir)
			@controller.root_directory=root_dir
		end
	
		def map_request(maplist)
			@controller.request_for_map(maplist)
		end
	
		# Controller��ROUTE�v���̈ꗗ���Z�b�g����B
		#
		# [routelist] "�t�@�C����(String),�^�[�Q�b�g��(String),�I�v�V����(Hash),diagram�o�̗͂v��(true or false)" �̔z��
		#
		# [returns] �s��
		def route_request(routelist)
			@controller.request_for_route(routelist)
		end

		# �\���t�@�C��(ant-hive.xml)�̓ǂݍ��݂��s���AAntHive::Controller�ւ̏����p�����[�^���Z�b�g����B
		#
		# [hivelist] ��`�ς�Hive����\�����镶����̔z��Bex) %w(sample sample2)
		def load_config_for(hivelist)
			@logger.debug(self.class){"Loading config from ant-hive.xml for [ #{hivelist.join(',')} ]."}
			root=REXML::Document.new(File.new('ant-hive.xml')).root

			hivelist.each{|hivename|
				@logger.debug(self.class){"Searching hive named:[ #{hivename} ]."}

				node=nil
				root.elements.each("./hive[@name=\"#{hivename}\"]"){|n| node=n }

				if node
					@logger.debug(self.class){"Hive config named:[ #{hivename} ] was found."}
					root_dir=nil
					map_list=[]
					route_list=[]

					node.elements.each{|hiveconf|
						options={}
						case hiveconf.name
						when 'root_directory'
							self.root_directory=(hiveconf.attributes['path'])
						when 'map'
							map_list.push hiveconf.attributes['file']
						when 'route'
							file=hiveconf.attributes['file']
							target=hiveconf.attributes['target']
							if hiveconf.attributes['with_diagram']=="true"
								with_diagram=true 
							else
								with_diagram=false
							end
							hiveconf.elements.each{|option_element|
								key=option_element.attributes['key']
								val=option_element.attributes['val']
								raise AntHiveError.new("Children of 'route' element should be 'options' only.") unless option_element.name == 'options'
								raise AntHiveError.new("'option' element should have 'key','val' attributes.") unless key && val

								options[key.strip]=val.strip
							}
							route_list.push [ file, target, options, with_diagram ]
							@logger.debug(self.class){"File:[ #{file} ], Target:[ #{target} ], Options:[ #{options} ]"}
						else
						end
					}
					self.map_request(map_list)
					self.route_request(route_list)
					self.run()
				else
					@logger.error(self.class){"Hive config named:[ #{hivename} ] was NOT found."}
				end
			}
		end

		def run
			@controller.run
		end
	end
end


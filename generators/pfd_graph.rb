#!ruby -Ks


module AntHive
  class PFD_Process
    def initialize(label,path,shape="component")
      @label=label
      @path=path
      @shape=shape
      case @shape
      when "component"; @color="orange1"
      else; @color="white"
      end
    end
    attr_reader :label, :path

    def ==(other)
      self.class==other.class && @label==other.label && @path==other.path
    end

    def identifyer
      unless @label==""
        self.object_id.to_s
      else
        ""
      end
    end

    def to_s
      "#{identifyer} [ label=\"#{@label}\" shape=\"#{@shape}\" style=\"filled\" fillcolor=\"#{@color}\" ]"
    end
  end

  class PFD_DataStore
    def initialize(name,shape)
      @name=name
      @shape=shape
      case @shape
      when "tab"; @color="khaki1"
      when "note"; @color="mintcream"
      else; @color="white"
      end
    end
    attr_reader :name

    def ==(other)
      self.class==other.class && @name==other.name
    end

    def identifyer
      self.object_id.to_s
    end

    def to_s
      "#{identifyer} [ label=\"#{@name}\" shape=\"#{@shape}\" style=\"filled\" fillcolor=\"#{@color}\"]"
    end
  end

  class PFD_DataFlow
    def initialize(from, to, description)
      @from=from
      @to=to
      @desc=description
      if @from.is_a?(PFD_Process) && @to.is_a?(PFD_Process)
        @style="solid"
      else
        @style="dashed"
      end
    end
    attr_reader :from, :to

    def ==(other)
      @from.class==other.from.class && @to.class==other.to.class && @from==other.from && @to==other.to
    end

    def to_s
      unless @from.identifyer==""
        "#{@from.identifyer} -> #{@to.identifyer} [ label=\"#{@desc}\" style=\"#{@style}\"]"
      end
    end
  end

	class PFDGraphGenerator
		def initialize(hive)
			@logger=SingletonLogger.instance()
			@root_directory=nil
			@hive=hive
      @pfd_processes=[]
      @pfd_datastores=[]
      @pfd_dataflows=[]
      @clustnumber=0
			@logger.debug(self.class){"#{self.class} initiated."}
		end
		attr_accessor :root_directory


		# PFDGraphを生成する。
		# initialize時に指定されたHiveに、引数で渡されたRoute構成情報が含まれない場合には、例外AntHiveErrorを生じる。
		#
		# [real_pah] routeの基点となるxml(ant)のパスを示す文字列(通常は、root_directoryからの相対パス)
		# [target] routeの基点となるターゲット名を示す文字列
		# [options] 動的経路評価実行時のプロパティ名⇒値のHash
    # [fake] 
		#
		# [returns] 生成したファイル名を示す文字列
		def generate(real_path,target,options,fake)
			raise AntHiveError.new("[ Bug ] Hive don't have route:[ #{target} ]@[ #{real_path} ] ") unless @hive.registed_route?(real_path,target,options)

			@route=@hive.routes(real_path,target,options)
      raise AntHiveError.new("Route:[ #{target}@#{real_path} with #{options} ] is not registed.") unless @route
			@logger.debug(self.class){"For requested route( #{target}@#{real_path} ), got [ #{route} ] route info."}

			#@routeより,プロセスボックス(target)、データストア(property file=やavailable等によるファイル入出力(cvs含む))を抽出する。
      construct(@route)
      graph(fake)
      self.outfile_svg
		end


    # AntHive::Hive::Routeより、経路情報のプロセスボックス、データフロー、データストアを抽出する。
    # [route] 動的評価パスの登録されたAntHive::Hive::Routeオブジェクト
    def construct(route)
      process_stack=[]
      route.each do |step|
        case step.tag
        when :toplevel_start
          push_process('TOPLEVEL',step.antpath,process_stack)
        when :toplevel_end
#          process=process_stack.pop
#          raise AntHiveError.new("[ Bug ] Toplevel_start and end missed.") unless process == PFD_Process.new("TOPLEVEL",step.antpath)
        when :target_start
          push_process(step.current_target,step.antpath,process_stack)
        when :target_end
#          process=process_stack.pop
#          raise AntHiveError.new("[ Bug ] Target_start and end missed.") unless process == PFD_Process.new(step.current_target,step.antpath)
        when :step
          case step.node_name
          when ''
            # enclosed tag

          when 'antcall','ant','subant','echo','fileset','exec','arg'
            # do nothing

          when 'property'
            raise AntHiveError.new("[ Bug ] property step is not REXML::Element.") unless step.node.is_a?(REXML::Element)
            if property_file=step.node.attributes['file']
              property_file=step.evaluated_value.scan(/\sfile=[\"\']([^\"\']+)[\"\']/).flatten.first
              current_process=process_stack.last
              current_process=PFD_Process.new('','') unless current_process
              store=PFD_DataStore.new(property_file,'note')
              flow=PFD_DataFlow.new(store, current_process,'load properties')
              regist_datastore store
              regist_dataflow flow
            elsif step.node.attributes['name'] || step.node.attributes['environment']
              # do nothing at PFD. it does not read/write from datastore.
            else
              @logger.warn(self.class){"property task like [ #{step.node} ] not implemented."}
            end


          when 'delete'
            raise AntHiveError.new("[ Bug ] delete step is not REXML::Element.") unless step.node.is_a?(REXML::Element)
            if target_dir=step.node.attributes['dir']
              target_dir=step.evaluated_value.scan(/\sdir=[\"\']([^\"\']+)[\"\']/).flatten.first
              current_process=process_stack.last
              current_process=PFD_Process.new('','') unless current_process
              store=PFD_DataStore.new(target_dir,'tab')
              flow=PFD_DataFlow.new(current_process,store,'delete')
              regist_datastore store
              regist_dataflow flow
            else
              @logger.warn(self.class){"delete task like [ #{step.node} ] not implemented."}
            end

          when 'mkdir'
            raise AntHiveError.new("[ Bug ] mkdir step is not REXML::Element.") unless step.node.is_a?(REXML::Element)
            if target_dir=step.node.attributes['dir']
              target_dir=step.evaluated_value.scan(/\sdir=[\"\']([^\"\']+)[\"\']/).flatten.first
              current_process=process_stack.last
              current_process=PFD_Process.new('','') unless current_process
              store=PFD_DataStore.new(target_dir,'tab')
              flow=PFD_DataFlow.new(current_process,store,'mkdir')
              regist_datastore store
              regist_dataflow flow
            else
              @logger.warn(self.class){"mkdir task like [ #{step.node} ] not implemented."}
            end

          when 'copy'
            raise AntHiveError.new("[ Bug ] copy step is not REXML::Element.") unless step.node.is_a?(REXML::Element)
            if step.node.attributes['file'] && ( step.node.attributes['tofile'] || step.node.attributes['todir'] )
              from=step.evaluated_value.scan(/\sfile=[\"\']([^\"\']+)[\"\']/).flatten.first
              if step.node.attributes['tofile'] 
                to=step.evaluated_value.scan(/\stofile=[\"\']([^\"\']+)[\"\']/).flatten.first
                shape='note'
              else
                to=step.evaluated_value.scan(/\stodir=[\"\']([^\"\']+)[\"\']/).flatten.first
                shape='tab'
              end
              current_process=process_stack.last
              current_process=PFD_Process.new('','') unless current_process
              store_from=PFD_DataStore.new(from,'note')
              store_to=PFD_DataStore.new(to,shape)
              flow_from=PFD_DataFlow.new(store_from,current_process,'copy')
              flow_to=PFD_DataFlow.new(current_process,store_to,'copy')
              regist_datastore store_from
              regist_datastore store_to
              regist_dataflow flow_from
              regist_dataflow flow_to
            else
              @logger.warn(self.class){"copy task like [ #{step.node} ] not implemented."}
            end

          when 'tar'
            raise AntHiveError.new("[ Bug ] tar step is not REXML::Element.") unless step.node.is_a?(REXML::Element)
            if step.node.attributes['destfile'] && step.node.attributes['basedir']
              from=step.evaluated_value.scan(/\sbasedir=[\"\']([^\"\']+)[\"\']/).flatten.first
              to=step.evaluated_value.scan(/\sdestfile=[\"\']([^\"\']+)[\"\']/).flatten.first
              current_process=process_stack.last
              current_process=PFD_Process.new('','') unless current_process
              store_from=PFD_DataStore.new(from,'tab')
              store_to=PFD_DataStore.new(to,'note')
              flow_from=PFD_DataFlow.new(store_from,current_process,'tar')
              flow_to=PFD_DataFlow.new(current_process,store_to,'tar')
              regist_datastore store_from
              regist_datastore store_to
              regist_dataflow flow_from
              regist_dataflow flow_to
            else
              @logger.warn(self.class){"tar task like [ #{step.node} ] not implemented."}
            end


          else
            p step.node_name
          end
        else
          raise AntHiveError.new("[ Bug ] Unknown tag type.")
        end
      end
    end

    def graph(fake)
			template=ERB.new(File.read('./generators/pfd.erb'))

			unless fake
				File.open(outfile_dot,'w'){|f| f.puts template.result(binding) }

				@logger.debug(self.class){"converting [ #{outfile_dot} ] into [ #{outfile_svg} ]. "}
				system("dot -Tsvg #{outfile_dot} -o #{outfile_svg}")
				@logger.error(self.class){"may not installed graphviz ? converting #{outfile_dot} was failed. "} unless $?==0
			end
			outfile_svg
    end

		def outfile_dot; OutFileName.outfile_for_route(@route,"_pfd.dot"); end
		def outfile_svg; OutFileName.outfile_for_route(@route,"_pfd.svg"); end

    def regist_process(process); @pfd_processes.push process; end
    def regist_datastore(store); @pfd_datastores.push store unless @pfd_datastores.find{|x| x == store }; end
    def regist_dataflow(flow); @pfd_dataflows.push flow; end

    def push_process(name,path,stack)
      # "前の"プロセスを取得。存在しない場合には無名のプロセス
      pre_process=stack.last
      pre_process=PFD_Process.new('','') unless pre_process

      process=PFD_Process.new(name,path)
      stack.push process
      flow=PFD_DataFlow.new(pre_process,process,'')

      regist_process process
      regist_dataflow flow
    end

    def write_cluster(path)
      member=@pfd_processes.find_all{|x| x.path==path }
      member_ids=member.collect{|x| x.identifyer }.join(" ")
      @clustnumber+=1
      result ="subgraph cluster_#{@clustnumber} {\n"
      result+="  label = \"#{path}\" \n"
      member.each do |process|
        result+="  #{process.to_s}\n"
      end
#      result+="  {rank = same; #{member_ids}; }"
      result+="}\n"
      result
    end


	end
end

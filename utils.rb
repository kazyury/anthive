#!ruby -Ks

module AntHive
	class AntHiveError < StandardError ; end

	module RealPath
		def self.realpath(root, request)
			path=Pathname.new(root+"/"+request).cleanpath.to_s
			raise AntHiveError.new("Requested path:[ #{path} ] is jumping over root directory:[ #{root} ]") if /#{root}/!~path
			unless File.exist?(path)
				raise AntHiveError.new("Requested path:[ #{path} ] does NOT exist.")
			end
			path
		end
	end

	module RelativePath
		def self.between(root,path)
			root=Pathname.new(root)
			path=Pathname.new(path)
			path.relative_path_from(root).to_s
		end
	end

  module OutFileName
    def self.outfile_for_route(route,suffix)
			fso=WIN32OLE.new('Scripting.FileSystemObject')
			outdir=File.dirname(route.file)
			basename=route.to_s
			specialchar=Regexp.new('[\<\>\?\[\]\:\|\*\/\\\\]')
			if specialchar=~basename
				basename.gsub!(specialchar,'_')
			end
			outfile =fso.GetAbsolutePathName("#{outdir}/#{basename}#{suffix}")
      outfile
    end
  end
end

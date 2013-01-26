#!ruby -Ks

require 'test_requirements'

module AntHive
class TestParser < Test::Unit::TestCase

	def setup
		logger=AntHive::SingletonLogger.instance
		logger.level=Logger::INFO
		@parser=Parser.new()
	end

	def test_001_initialize
		# Parserの使い方
		# Parser#parseをいきなり実行してはいけない。
		assert_raises(AntHiveError){ @parser.parse('data/build.xml')}
	end

	def test_002_root_directory
		# Parser#root_directory=
		# 存在しないディレクトリをroot_directoryとしてはいけない。
		# 存在するディレクトリは指定できなければいけない
		assert_raises(AntHiveError){ @parser.root_directory='data_not_found' }
		assert_nothing_raised{ @parser.root_directory='data' }
		assert_nothing_raised{ @parser.root_directory='./data' }
		assert_nothing_raised{ @parser.root_directory='data/' }
	end

	def test_003_root_directory2
		# Parser#root_directory=
		# 末尾に/がついていたら、/を外した状態になっていなければならない。
		@parser.root_directory='data/'
		assert_equal('data',@parser.root_directory)

		@parser.root_directory='data//'
		assert_equal('data',@parser.root_directory)

		@parser.root_directory='data/data2/'
		assert_equal('data/data2',@parser.root_directory)
	end

	def test_004_root_directory3
		# Parser#root_directory=
		# 存在しないディレクトリは例外
		assert_raises(AntHive::AntHiveError){@parser.root_directory='not_exist'}
	end

	def test_005_parse
		# Parser#parse
		# - Parser#parseには、実際のパスを指定しなければならない。
		#   (@root_directoryからの相対パス*ではない*)
		# - 存在するファイルでなければならない。
		@parser.root_directory='data'
		assert_raises(AntHiveError){ @parser.parse('build.xml') }
		assert_nothing_raised{ @parser.parse('data/build.xml') }
		assert_raises(AntHiveError){ @parser.parse('data/ant-hive.xml') }
	end

	def test_006_parse2
		# Parser#parse
		# - Parser#parseの返値はAntObject::Project
		# - AntObject::Projectには正しいTarget等が指定されていなければならない。(data/build.xml)
		@parser.root_directory='data'
		result=@parser.parse('data/build.xml')
		assert_kind_of(AntObject::Project, result)
		assert_equal('data/build.xml',result.real_path)
		assert_equal('anthive',result.name)
		assert_equal('.',result.basedir)
		assert_equal('default',result.default)
		assert_equal(7,result.targets.size)

		nodes=result.all_nodes

		node=nodes.shift
		assert_kind_of(AntObject::Property,node)
		assert_equal('VERSION',node.file)
		assert_equal(true,node.environment.nil?)
		assert_equal(true,node.name.nil?)
		assert_equal(true,node.value.nil?)

		node=nodes.shift
		assert_kind_of(AntObject::Property,node)
		assert_equal(true,node.file.nil?)
		assert_equal(true,node.environment.nil?)
		assert_equal('exerb.core',node.name)
		assert_equal('D:/ruby/share/exerb/ruby184c.exc' ,node.value)

		node=nodes.shift
		assert_kind_of(AntObject::Target,node)
		assert_equal('default',node.name)
		assert_equal(true,node.if.nil?)
		assert_equal(true,node.unless.nil?)
		assert_equal(true,node.depends.empty?)
		assert_equal(true,node.calls.empty?)
		assert_equal(false,node.description.nil?)

		node=nodes.shift
		assert_kind_of(AntObject::Target,node)
		assert_equal('release',node.name)
		assert_equal(true,node.if.nil?)
		assert_equal(true,node.unless.nil?)
		assert_equal(true,node.depends.empty?)
		cals=node.calls
		assert_equal([:antcall, 'build.xml','run_unit_test'],cals.shift)
		assert_equal([:antcall, 'build.xml','generate_docs'],cals.shift)
		assert_equal([:antcall, 'build.xml','generate_exe'],cals.shift)
		assert_equal([:antcall, 'build.xml','package'],cals.shift)
		assert_equal('Run unit-test, Generate docs, Generate Executables, and Packaging.',node.description)

		node=nodes.shift
		assert_kind_of(AntObject::Target,node)
		assert_equal('run_unit_test',node.name)
		assert_equal(true,node.if.nil?)
		assert_equal(true,node.unless.nil?)
		assert_equal(true,node.depends.empty?)
		assert_equal(true,node.calls.empty?)
		assert_equal('Run unit-test',node.description)

		node=nodes.shift
		assert_kind_of(AntObject::Target,node)
		assert_equal('generate_docs',node.name)
		assert_equal(true,node.if.nil?)
		assert_equal(true,node.unless.nil?)
		assert_equal(true,node.depends.empty?)
		assert_equal(true,node.calls.empty?)
		assert_equal('Generate Rdoc document.',node.description)

		node=nodes.shift
		assert_kind_of(AntObject::Target,node)
		assert_equal('generate_exe',node.name)
		assert_equal(true,node.if.nil?)
		assert_equal(true,node.unless.nil?)
		assert_equal(['make_recipe'],node.depends)
		assert_equal(true,node.calls.empty?)
		assert_equal('Generate Win32 Executables.',node.description)

		node=nodes.shift
		assert_kind_of(AntObject::Target,node)
		assert_equal('package',node.name)
		assert_equal(true,node.if.nil?)
		assert_equal(true,node.unless.nil?)
		assert_equal(true,node.depends.empty?)
		assert_equal(true,node.calls.empty?)
		assert_equal('Packages executables,rdoc,and so on.',node.description)

		node=nodes.shift
		assert_kind_of(AntObject::Target,node)
		assert_equal('make_recipe',node.name)
		assert_equal(true,node.if.nil?)
		assert_equal(true,node.unless.nil?)
		assert_equal(true,node.depends.empty?)
		assert_equal(true,node.calls.empty?)
		assert_equal('Generate exerb recipe file for Win32 Executables.',node.description)
	end

end
end


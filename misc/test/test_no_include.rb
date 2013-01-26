#!ruby -Ks

$:.unshift('..')
require 'test/unit'
require 'property_file.rb'

class TestPropertyFileNotInclude < Test::Unit::TestCase

	def test_no_inclusion_001
		contents=PropertyFile.read_property('data/package_info.properties')
		assert_equal('JPShinseiDB-conf',contents['rpkg.conf.prj'])
		assert_equal('JPShinsei',contents['rpkg.source.prj.list'])
		assert_equal('QMJPSQ0C20A2',contents['rpkg.prj.qm.name'])
		assert_equal('JPSQ0C20A',contents['rpkg.mqfw.rule.connecthost'])
		assert_equal('SVRCON.QMJPSQ0C20A2',contents['rpkg.mqfw.rule.connectchannel'])
		assert_equal('systemA',contents['rpkg.system.list'])
		assert_equal('JPARTNER.A.DBBatch',contents['rpkg.systemA.rpkg.name'])
		assert_equal('QMJPSQ0C20A2',contents['rpkg.systemA.qm.name'])
		assert_equal('${pkg.dir.prefix}/appl/mqstar/a/**/*.java, ${pkg.dir.prefix}/appl/sql/a/**/*.java, ${pkg.dir.prefix}/appl/util/a/**/*.java, ${pkg.dir.prefix}/appl/mqstar/r1/**/*.java, ${pkg.dir.prefix}/appl/sql/r1/**/*.java, ${pkg.dir.prefix}/appl/util/r1/**/*.java, ${pkg.dir.prefix}/appl/mqstar/t/**/*.java, ${pkg.dir.prefix}/appl/sql/t/**/*.java, ${pkg.dir.prefix}/appl/util/t/**/*.java, ${pkg.dir.prefix}/appl/mqstar/z/**/*.java, ${pkg.dir.prefix}/appl/sql/z/**/*.java, ${pkg.dir.prefix}/appl/util/z/**/*.java',contents['rpkg.JPShinsei.compile.inc'])
		assert_equal('appl-mqstar-a.jar,appl-common-a.jar',contents['rpkg.subsys.jar.list'])
		assert_equal('${prj.jp-jars}/appl-util/appl-multi-dshinsei.jar, ${prj.jp-jars}/appl-util/appl-multi-touroku.jar, ${prj.jp-jars}/appl-common/appl-mqstar-z.jar, ${prj.jp-jars}/appl-util/appl-multi-util.jar, ${prj.jp-jars}/appl-util/appl-multi-shinsei.jar',contents['rpkg.depend.jar.list'])
		assert_equal('JPARTNER.A.DBBatch.VF',contents['release.package.vf'])
	end
end

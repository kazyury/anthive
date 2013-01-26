#!ruby -Ks

$:.unshift('..')
require 'test/unit'
require 'property_file.rb'

class TestPropertyFileNotInclude < Test::Unit::TestCase

	def test_misc_001
		base=PropertyFile.read_property('data/package_info.properties')
		aliased=PropertyFile.properties('data/package_info.properties')
		assert_equal(base,aliased)
	end

end

class TestPropertyFile < Test::Unit::TestCase
	include PropertyFile

	def test_misc_001
		base=read_property('data/package_info.properties')
		aliased=properties('data/package_info.properties')
		assert_equal(base,aliased)
	end

end

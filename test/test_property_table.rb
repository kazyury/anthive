#!ruby -Ks

require 'test_requirements'

class TestPropertyTable < Test::Unit::TestCase
	def setup
		logger=AntHive::SingletonLogger.instance
		logger.level=Logger::INFO
		@table=AntHive::PropertyTable.new()
	end

	def test_001_regist
		assert_nothing_raised{@table.regist('key1','val1')}
		assert_nothing_raised{@table.regist('key2','${key1}')}
		assert_nothing_raised{@table.regist('key3','${key2}')}
		assert_nothing_raised{@table.regist('key4','${key1}/${key2}/${key3}')}
		assert_nothing_raised{@table.regist('key5','${${key1}/${key2}/${key3}}.txt')}
		assert_nothing_raised{@table.regist('val1/val1/val1','hoge')}
		assert_equal(true,@table.registed?('key1'))
		assert_equal(true,@table.registed?('key2'))
		assert_equal(true,@table.registed?('key3'))
		assert_equal(true,@table.registed?('key4'))
		assert_equal(true,@table.registed?('key5'))
		assert_equal(true,@table.registed?('val1/val1/val1'))
	end

	def test_002_value_for
		assert_nothing_raised{@table.regist('key1','val1')}
		assert_nothing_raised{@table.regist('key2','${key1}')}
		assert_nothing_raised{@table.regist('key3','${key2}')}
		assert_nothing_raised{@table.regist('key4','${key1}/${key2}/${key3}')}
		assert_nothing_raised{@table.regist('key5','${${key1}/${key2}/${key3}}.txt')}
		assert_nothing_raised{@table.regist('val1/val1/val1','hoge')}
		assert_equal('val1',@table.value_for('key1'))
		assert_equal('val1',@table.value_for('key2'))
		assert_equal('val1',@table.value_for('key3'))
		assert_equal('val1/val1/val1',@table.value_for('key4'))
		assert_equal('hoge.txt',@table.value_for('key5'))
	end

	def test_003_expand
		assert_nothing_raised{@table.regist('key1','val1')}
		assert_nothing_raised{@table.regist('key2','val2')}
		assert_nothing_raised{@table.regist('key3','val3')}
		assert_equal('hoge',@table.expand('hoge'))
		assert_equal('${hoge}',@table.expand('${hoge}'))
		assert_equal('',@table.expand(''))
		assert_equal('${}',@table.expand('${}'))
		assert_equal('val1',@table.expand('${key1}'))
		assert_equal('val1/val2/val3'   ,@table.expand('${key1}/${key2}/${key3}'))
		assert_equal('${hoge}/val2/val3',@table.expand('${hoge}/${key2}/${key3}'))
		assert_equal('val1/${hoge}/val3',@table.expand('${key1}/${hoge}/${key3}'))
		assert_equal('val1/val2/${hoge}',@table.expand('${key1}/${key2}/${hoge}'))
	end

	def test_004_expand_2 # nested expansion
		assert_nothing_raised{@table.regist('cvs1.srv.com','127.0.0.1')}
		assert_nothing_raised{@table.regist('mod1','cvs1')}
		assert_equal('cvs1',@table.expand('${mod1}'))
		assert_equal('cvs1.srv.com',@table.expand('${mod1}.srv.com'))
		assert_equal('127.0.0.1',@table.expand('${${mod1}.srv.com}'))
	end

	def test_005_expand_3 # ˆÓ’nˆ«
		assert_nothing_raised{@table.regist('mod1','cvs1')}
		assert_nothing_raised{@table.regist('${mod1','*** NG ***')}
		assert_equal('cvs1',@table.expand('${mod1}'))
		assert_equal('${cvs1.srv.com',@table.expand('${${mod1}.srv.com'))   # ––”öF•Â‚¶’†Š‡ŒÊ‚È‚µ
		assert_equal('${cvs1.srv.com}',@table.expand('${${mod1}.srv.com}')) # ––”öF•Â‚¶’†Š‡ŒÊ‚ ‚è
	end

	def test_006_deep_copy
		assert_nothing_raised{@table.regist('key1','val1')}
		assert_nothing_raised{@table.regist('key2','val2')}
		assert_nothing_raised{@table.regist('key3','val3')}
		other=@table.deep_copy
	end

	def test_007_expandables
		assert_equal([],@table.expandables('hoge'))
		assert_equal([],@table.expandables('$ho{ge}'))
		assert_equal(['hoge'],@table.expandables('${hoge}'))
		assert_equal(['hoge','foo'],@table.expandables('${hoge}/${foo}'))
		assert_equal(['hoge','foo'],@table.expandables('${hi${hoge}/${foo}}'))
		assert_equal(['hoge','foo'],@table.expandables('${}${hoge}/${foo}}'))
		assert_equal([' ','hoge','foo'],@table.expandables('${ }${hoge}/${foo}}'))
	end

end

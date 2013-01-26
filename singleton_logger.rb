

module AntHive
	# AntHiveの各処理で共通で使用するLoggerインタフェース
	# Singletonなので全処理で1つのLoggerオブジェクトを参照する。
	# ( 使い方の例 )
	#		Class Hoge
	#			def initialize
	#				@logger=SingletonLogger.instance  <------+
	#			end                                        |
	#		end                                          |
	#		attr_reader :logger                          |
	# 	                                             |同一のインスタンスを指す。 
	#		class Foo                                    |
	#			def initialize                             |
	#				@logger=SingletonLogger.instance  <------+
	#			end
	#		end
	#		attr_reader :logger
	#
	#		hogelogger=Hoge.new.logger
	#		foo_logger=Foo.new.logger
	#
	#		hogelogger.level=Logger::FATAL #=>foo_loggerのログレベルもFATALに変更
	class SingletonLogger
		include Singleton
		extend Forwardable
		
		def initialize
			@logger=Logger.new(STDOUT)
		end

		def_delegators(:@logger,"datetime_format","datetime_format=")
		def_delegators(:@logger,"debug?","info?","warn?","error?","fatal?","debug","info","warn","error","fatal")
		def_delegators(:@logger,"level","level=","sev_threshold","sev_threshold=","progname","progname=" )

		def _dump(l); ''; end
		def self._load(obj)
			self.instance
		end

	end
end


#!ruby -Ks

# ruby's
require 'forwardable'
require 'kconv'
require 'logger'
require 'pathname'
require 'rexml/document'
require 'singleton'
require 'optparse'
require 'win32ole'
require 'erb'

# ant-hive's
require 'antobject/anon_node'
require 'antobject/project'
require 'antobject/property'
require 'antobject/target'
require 'controller'
require 'evaluater'
require 'generators/map_graph'
require 'generators/route_trace'
require 'generators/pfd_graph'
require 'hive'
require 'parser'
require 'property_table'
require 'singleton_logger'
require 'ui/cui'
require 'utils'

# independent (but,mine.)
require 'misc/property_file'





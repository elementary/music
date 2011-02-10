#! /usr/bin/env python
# encoding: utf-8
# WARNING! All changes made to this file will be lost!

import os,sys,imp,types
from waflib import Utils,Configure,Options,Logs,Errors
from waflib.Tools import fc
fc_compiler={'win32':['gfortran','ifort'],'darwin':['gfortran','g95','ifort'],'linux':['gfortran','g95','ifort'],'java':['gfortran','g95','ifort'],'default':['gfortran']}
def __list_possible_compiler(platform):
	try:
		return fc_compiler[platform]
	except KeyError:
		return fc_compiler["default"]
def configure(conf):
	try:test_for_compiler=conf.options.check_fc
	except AttributeError:conf.fatal("Add options(opt): opt.load('compiler_fc')")
	orig=conf.env
	for compiler in test_for_compiler.split():
		try:
			conf.start_msg('Checking for %r (fortran compiler)'%compiler)
			conf.env=orig.derive()
			conf.load(compiler)
		except conf.errors.ConfigurationError ,e:
			conf.end_msg(False)
			Logs.debug('compiler_fortran: %r'%e)
		else:
			if conf.env['FC']:
				orig.table=conf.env.get_merged_dict()
				conf.env=orig
				conf.end_msg(True)
				conf.env.COMPILER_FORTRAN=compiler
				break
			conf.end_msg(False)
	else:
		conf.fatal('could not configure a fortran compiler!')
def options(opt):
	build_platform=Utils.unversioned_sys_platform()
	detected_platform=Options.platform
	possible_compiler_list=__list_possible_compiler(detected_platform)
	test_for_compiler=' '.join(possible_compiler_list)
	fortran_compiler_opts=opt.add_option_group("Fortran Compiler Options")
	fortran_compiler_opts.add_option('--check-fortran-compiler',default="%s"%test_for_compiler,help='On this platform (%s) the following Fortran Compiler will be checked by default: "%s"'%(detected_platform,test_for_compiler),dest="check_fc")
	for compiler in test_for_compiler.split():
		opt.load('%s'%compiler)

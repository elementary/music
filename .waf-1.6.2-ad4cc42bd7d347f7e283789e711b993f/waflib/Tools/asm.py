#! /usr/bin/env python
# encoding: utf-8
# WARNING! All changes made to this file will be lost!

import os,sys
from waflib import Task,Utils
import waflib.Task
from waflib.Tools.ccroot import link_task,stlink_task
from waflib.TaskGen import extension,feature
class asm(Task.Task):
	color='BLUE'
	run_str='${AS} ${ASFLAGS} ${CPPPATH_ST:INCPATHS} ${AS_SRC_F}${SRC} ${AS_TGT_F}${TGT}'
def asm_hook(self,node):
	return self.create_compiled_task('asm',node)
class asmprogram(link_task):
	run_str='${ASLINK} ${AS_TGT_F}${TGT} ${SRC}'
	ext_out=['.bin']
	inst_to='${BINDIR}'
	chmod=Utils.O755
class asmshlib(asmprogram):
	inst_to='${LIBDIR}'
class asmstlib(stlink_task):
	pass

extension('.s','.S','.asm','.ASM','.spp','.SPP')(asm_hook)
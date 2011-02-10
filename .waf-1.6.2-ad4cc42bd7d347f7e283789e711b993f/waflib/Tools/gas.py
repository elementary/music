#! /usr/bin/env python
# encoding: utf-8
# WARNING! All changes made to this file will be lost!

import waflib.Tools.asm
from waflib.Tools import ar
def configure(conf):
	conf.find_program(['gas','as','gcc'],var='AS')
	conf.env.AS_TGT_F='-o'
	conf.find_ar()

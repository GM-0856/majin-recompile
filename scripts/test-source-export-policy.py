"""Exercise source-companion binary bypasses and scoped upstream omissions."""
from pathlib import Path
import importlib.util

spec=importlib.util.spec_from_file_location('source_packager',Path(__file__).with_name('package-alpha-source.py'))
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
checks=0
def check(ok,message):
    global checks
    if not ok:raise AssertionError(message)
    checks+=1

pe=bytearray(132);pe[:2]=b'MZ';pe[60:64]=(128).to_bytes(4,'little');pe[128:]=b'PE\0\0'
for name,data in [('innocent.h',bytes(pe)),('tool',b'\x7fELFpayload'),('license.lib',b'!<arch>\npayload'),('darwin-tool',b'\xcf\xfa\xed\xfepayload'),('universal-tool',b'\xca\xfe\xba\xbepayload'),('renamed.exe',b'not-a-PE'),('module.dll',b'not-a-PE'),('wrapper.jar',b'PK\x03\x04payload')]:
    check(module.is_compiled_blob(name,data),'Compiled file bypass: '+name)
for name,data in [('COPYING.LIB',b'GNU LESSER GENERAL PUBLIC LICENSE\n'),('source.cpp',b'// MZ is a DOS signature\n'),('logo.png',b'\x89PNG\r\n\x1a\n'),('header.h',b'MZ'+b'x'*65)]:
    check(not module.is_compiled_blob(name,data),'Source/notice false positive: '+name)
for name in ['ReXGlue/tools/binutils/powerpc-none-elf-as','ReXGlue/tools/binutils/powerpc-none-elf-as.exe','ReXGlue/thirdparty/imgui/examples/libs/glfw/lib-vc2010-32/glfw3.lib','ReXGlue/thirdparty/imgui/examples/libs/glfw/lib-vc2010-64/glfw3.lib','ReXGlue/thirdparty/sdl3/android-project/gradle/wrapper/gradle-wrapper.jar']:
    check(module.omit_prebuilt(name),'Known optional prebuilt not omitted: '+name)
for name in ['ReXGlue/tools/binutils/LICENSE','ReXGlue/tools/binutils-other/tool.exe','Project/tools/binutils/tool.exe','ReXGlue/thirdparty/imgui/imgui.cpp']:
    check(not module.omit_prebuilt(name),'Omission too broad: '+name)
print(f'PASS: {checks} source-export policy checks; disguised binaries rejected, text licenses preserved, omission boundaries scoped.')

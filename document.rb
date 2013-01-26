#!ruby -Ks

#AntHive�̃h�L�������g��Rdoc�ɑg�ݍ��ނ��߂̖��O��Ԃł��B
module AntHiveDocument

	#== First Step
	#���͂Ƃ�����g���Ă݂܂��傤�Banthive�ɂ�sample�𓯍����Ă��܂��B
	#
	#sample�f�B���N�g���̍\���͈ȉ��̂悤�ɂȂ��Ă��܂��B
	# sample/
	#   build.xml
	#   VERSION
	#
	#�����ŁAbuild.xml�͂Ƃ���A�v���P�[�V�����̃����[�X�pant�X�N���v�g�ł��B
	#VERSION�t�@�C���̓v���p�e�B�t�@�C���Ƃ��Ďg�p���Ă��܂��B
	#
	#=== MAP of 'sample/build.xml'.
	#����build.xml�̐ÓI�ȍ\����\���Ă݂܂��傤�B
	#�R�}���h���C�����A�ȉ��̂悤�Ɏ��s���Ă��������B(�ȉ��A��Ƃ��Ă�Win32�o�C�i���ł�ant-hive.exe���g�p���Ă���ꍇ��z�肵�Ă��܂��B)
	#
	# E:\Home\kz\anthive>ant-hive -r sample -M build.xml
	#
	#�ȉ��̂悤�ȃ��O�����炸��ƕ\������āA�G���[�炵�����̂�������Ȃ����OK�ł��B
	# I, [2008-01-27T21:12:03.140000 #996]  INFO -- AntHive::CUI: ant-hive is starting. Log level is [ 1 ].
	# I, [2008-01-27T21:12:04.281000 #996]  INFO -- AntHive::Controller: ========================================
	# I, [2008-01-27T21:12:04.296000 #996]  INFO -- AntHive::Controller: Ant-hive is running with these settings.
	# I, [2008-01-27T21:12:04.296000 #996]  INFO -- AntHive::Controller:      root_directory    : [ sample ]
	# I, [2008-01-27T21:12:04.312000 #996]  INFO -- AntHive::Controller:      request for map   : [ build.xml ]
	# I, [2008-01-27T21:12:04.312000 #996]  INFO -- AntHive::Controller: Starting static-parse for [ sample/build.xml ].
	# I, [2008-01-27T21:12:04.390000 #996]  INFO -- AntHive::Controller: Static map for [ sample/build.xml ] was generated.
	# I, [2008-01-27T21:12:13.046000 #996]  INFO -- AntHive::Controller: [ sample.svg ] was successfully generated as MAP.
	#
	#�����ăJ�����g�f�B���N�g���ɁAsample.dot �� sample.svg ���o�͂���Ă��锤�ł��B
	#sample.svg���Abuld.xml�̐ÓI�\�����������}�ł��BSVG�r���[���ŕ\�����Ă݂Ă��������B
	#link:sample.png
	#
	#ant�X�N���v�g���̊e�^�[�Q�b�g�́A1�̔�(Node)�ŕ\������܂��B
	#�����āA���̔��Ɣ��̊Ԃɖ��(Edge)��������Ă���ꍇ�ɂ́A���̊Ԃɉ��炩�̎��s�������݂��邱�Ƃ�\�����Ă��܂��B
	#�}��͈ȉ��̂Ƃ���ł��B
	#- �����ŁA��悪�ʏ�̖��
	#  - sample/build.xml�ł́Arelease ���� package, release����run_unit_test�Ɉ�����Ă�����ł��B
	#  - ���̖��͖�̃^�[�Q�b�g����A���̃^�[�Q�b�g��antcall�^�X�N�ɂ����s���Ă��邱�Ƃ�\�����Ă��܂��B
	#- �����ŁA��悪�������̕H�`
	#  - sample/build.xml�ł́Arelease ���� generate_docs�Ɉ�����Ă�����ł��B
	#  - ���̖��͖�̃^�[�Q�b�g����A���̃^�[�Q�b�g��ant�^�X�N�ɂ����s���Ă��邱�Ƃ�\�����Ă��܂��B
	#- �����ŁA��悪�������̔��H�`
	#  - sample/build.xml�ł́Arelease ���� generate_exe�Ɉ�����Ă�����ł��B
	#  - ���̖��͖�̃^�[�Q�b�g����A���̃^�[�Q�b�g��subant�^�X�N�ɂ����s���Ă��邱�Ƃ�\�����Ă��܂��B
	#- �j���ŁA��悪�ʏ�̖��
	#  - sample/build.xml�ł́Amake_recipe ���� generate_exe�Ɉ�����Ă�����ł��B
	#  - ���̖��́A���(generate_exe)���(make_recipe)�Ɉˑ����Ă��邽�߂ɁA����Ɏ��s���Ă���A
	#    ��悪���s����邱�Ƃ�\�����Ă��܂��B
	#    ���̔j���̖��́A���̎������ƈقȂ�A�ďo�֌W��\�����Ă���킯�ł͂Ȃ����Ƃɒ��ӂ��Ă��������B
	#
	#=== ROUTE of 'release' target of 'sample/build.xml'.
	#���ɁAsample/build.xml��release�^�[�Q�b�g�����s�����Ƃ��ɁA�ǂ̂悤�Ȍo�H��p���ăr���h���s���Ă���̂���
	#�m�F���܂��傤�B
	#�R�}���h���C�����A�ȉ��̂悤�Ɏ��s���Ă��������B
	#
	# E:\Home\kz\anthive>ant-hive -r sample -R "release@build.xml"
	#
	#�ȉ��̂悤�ȃ��O�����炸��ƕ\������āA�G���[�炵�����̂�������Ȃ����OK�ł��B
	# I, [2008-01-27T21:53:19.828000 #1264]  INFO -- AntHive::CUI: ant-hive is starting. Log level is [ 1 ].
	# I, [2008-01-27T21:53:24.937000 #1264]  INFO -- AntHive::Controller: ========================================
	# I, [2008-01-27T21:53:24.953000 #1264]  INFO -- AntHive::Controller: Ant-hive is running with these settings.
	# I, [2008-01-27T21:53:24.953000 #1264]  INFO -- AntHive::Controller:     root_directory    : [ sample ]
	# I, [2008-01-27T21:53:24.953000 #1264]  INFO -- AntHive::Controller:     request for map   : [  ]
	# I, [2008-01-27T21:53:24.953000 #1264]  INFO -- AntHive::Controller:     request for route : [[build.xml,release]]
	# I, [2008-01-27T21:53:24.968000 #1264]  INFO -- AntHive::Controller: Starting static-parse for [ sample/build.xml ].
	# I, [2008-01-27T21:53:25.078000 #1264]  INFO -- AntHive::Controller: Starting dynamic-evaluation for File:[ sample/build.xml ], Target:[ release ], Options:[  ].
	# W, [2008-01-27T21:53:25.296000 #1264]  WARN -- AntHive::RouteTraceGenerator: writing to Microsoft Excel. -- DO NOT USE Excel -- until ends.
	# I, [2008-01-27T21:53:30.531000 #1264]  INFO -- AntHive::Controller: [ sample/release_at_build.xls ] was successfully generated for [ release ]@[ build.xml ] with [  ], ROUTE.
	#
	#�����āAsample�f�B���N�g���� release_at_build.xls �t�@�C�����쐬����Ă��邱�Ƃ��m�F���Ă��������B
	#���̃t�@�C���͂��̂悤�ɂȂ��Ă���͂��ł��B
	#link:release_at_build.png
	#
	#release�^�[�Q�b�g����̓��I�o�H��\�����邱��ROUTE�ł́AMAP�Ƃ͈قȂ�AAnt�X�N���v�g�̂ǂ̍s���ǂ̃^�C�~���O�Ŏ��s����邩��
	#������x�̐��m���ŕ\�����Ă��܂��B
	#���̗�ł́A
	#1. sample/build.xml �� release�^�[�Q�b�g���J�n���ꂽ�B(������Entering target:release @.....)
	#2. ���̃^�[�Q�b�g�ŁAantcall�^�X�N(target="run_unit_test")���]�������B
	#3. sample/build.xml �� run_unit_test�^�[�Q�b�g���J�n���ꂽ�B
	#4. ���ǁA����������run_unit_test�^�[�Q�b�g�𔲂����B(Leaving target:run_unit_test @ .....)
	#   (����́Arelease�^�[�Q�b�g�ɖ߂������ƂɂȂ�)
	#5. ���̃^�[�Q�b�g(release)�ŁAant�^�X�N(target="generate_docs")���]�������B
	#6. ant�^�X�N��antfile���w�肳��Ă��Ȃ��̂ŁA�f�t�H���g�t�@�C������build.xml��generate_docs�^�[�Q�b�g���J�n����B
	#7. <exec dir='${basedir}' executable='rdoc.bat'>���]�����ꂽ�B
	#   ���̃m�[�h�ɂ́A�v���p�e�B�W�J������${basedir}�����݂���̂ŁA���̎��_�ł̃v���p�e�B�l��]���������ʂł���A
	#   <exec dir='.' executable='rdoc.bat'>�����̍s�ɁA�Q�l���x�Ƃ��āA�Α̎��ŒǋL�B
	#8. and so on.
	#���X�����̏o�̓t�@�C���ɕ\�����Ă��܂��B
	class FirstStep ; end
	
	#== Options.
	#ant-hive�͊�{�I�ɂ̓R���\�[���A�v���ł��B
	#���s���I�v�V�����Ƃ��āA-g ���� --gui��ݒ肷���GUI���[�h�ŗ����オ��\��ł����A
	#��Version�ł͖������ł��B
	#
	#ant-hive�ɂ͕����̃I�v�V����������܂����A��{�I�ȃp�^�[���͌����Ă��܂��B
	#
	#- ant-hive -g
	#  - GUI���[�h�ŋN�����܂�(������)�B
	#
	#- ant-hive -H ��`�ς�hive��
	#  - ���f�B���N�g����ant-hive.xml���Œ�`���ꂽ��`�ς�hive����p���ċa�̑���\���܂��B
	#    �ł���ʓI�Ȏg�p���@�ł��B
	#    sample/build.xml��\�����߂ɂ́Aant-hive -H sample �Ƃ��Ă݂Ă��������B
	#
	#- ant-hive -r ant_root -M map���X�g -R route���X�g
	#  - ��񂱂�����̍�ƂȂ�΂�����܂��ǂ��ł��傤�B
	#    sample/build.xml�̑S��map�ƁArelease�^�[�Q�b�g����n�܂��A��route��\���ɂ́Aant-hive -r sample -M build.xml -R release@build.xml �Ƃ��Ă݂Ă��������B
	#
	#�R�}���h�����s����ƁA�ȉ��̗l�ɃR���\�[����Ƀ��O���o�͂���܂��B
	#�f�t�H���g�ł́AInfo, Warn, Error�����̃��O���o�͂���܂��B
	#
	# E:\Home\kz\anthive>ant-hive -H sample
	# I, [2008-01-26T21:13:15.031000 #1820]  INFO -- AntHive::CUI: ant-hive is starting. Log level is [ 1 ].
	# I, [2008-01-26T21:13:16.187000 #1820]  INFO -- AntHive::Controller: ========================================
	# I, [2008-01-26T21:13:16.187000 #1820]  INFO -- AntHive::Controller: Ant-hive is running with these settings.
	# I, [2008-01-26T21:13:16.187000 #1820]  INFO -- AntHive::Controller:     root_directory    : [ sample ]
	# I, [2008-01-26T21:13:16.187000 #1820]  INFO -- AntHive::Controller:     request for map   : [ build.xml ]
	# I, [2008-01-26T21:13:16.187000 #1820]  INFO -- AntHive::Controller:     request for route : [[build.xml,release,],[build.xml,generate_exe,]]
	# I, [2008-01-26T21:13:16.203000 #1820]  INFO -- AntHive::Controller: Starting static-parse for [ sample/build.xml ].
	# I, [2008-01-26T21:13:16.218000 #1820]  INFO -- AntHive::Controller: Starting dynamic-evaluation for File:[ sample/build.xml ], Target:[ release ], Options:[  ].
	# I, [2008-01-26T21:13:16.234000 #1820]  INFO -- AntHive::Controller: Starting dynamic-evaluation for File:[ sample/build.xml ], Target:[ generate_exe ], Options:[  ].
	# I, [2008-01-26T21:13:16.250000 #1820]  INFO -- AntHive::Controller: Static map for [ sample/build.xml ] was generated.
	# I, [2008-01-26T21:13:16.484000 #1820]  INFO -- AntHive::Controller: [ sample.svg ] was successfully generated as MAP.
	# W, [2008-01-26T21:13:16.500000 #1820]  WARN -- AntHive::RouteTraceGenerator: writing to Microsoft Excel. -- DO NOT USE Excel -- until ends.
	# I, [2008-01-26T21:13:17.625000 #1820]  INFO -- AntHive::Controller: [ sample/release_at_build.xls ] was successfully generated for [ release ]@[ build.xml ] with [  ], ROUTE.
	# W, [2008-01-26T21:13:17.625000 #1820]  WARN -- AntHive::RouteTraceGenerator: writing to Microsoft Excel. -- DO NOT USE Excel -- until ends.
	# I, [2008-01-26T21:13:18.218000 #1820]  INFO -- AntHive::Controller: [ sample/generate_exe_at_build.xls ] was successfully generated for [ generate_exe ]@[ build.xml ] with [  ], ROUTE.
	#
	#-d, -q �I�v�V�����̓��O�o�͂̃��x����ύX���܂��B
	#- -d, --debug �f�o�b�O���[�h�ł��B�����قǑ�ʂ̃��O��f���Ă���܂��B
	#- -q, --quiet �Â��ɂ��郂�[�h�ł��BError�ȊO�ɂ̓��O��f���܂���B�������AError���r���Ŕ������Ă��o��������͂𑱂��悤�Ƃ��܂��B
	#
	#�Ȃ� -f, --fake �I�v�V�����A�����͖Y��Ă��������B�a�̑���\���ɂ͕s�v�ȃI�v�V�����ł��B
	#�����̃I�v�V�����́Aant-hive -h �ŎQ�Ƃ��邱�Ƃ��o���܂��B
	#
	# ant-hive.
	# --- Search ant's hive deeply, and reveal their world map. :)
	# [usage]
	# ruby ant-hive.rb [-d|-q] -g
	#                  [-d|-q] -H HIVELIST
	#                  [-d|-q] -r PATH [-M MAPLIST] [-R ROUTELIST]
	#                  -h
	# ------------------------------------------------------------
	# ant-hive.exe also works. thanks to exerb.
	#
	#     -d, --debug                      Debug log appears
	#     -f, --fake                       Only run for generating exerb recipe.
	#     -g, --gui                        Launch GUI window
	#     -h, --help                       Show this message
	#     -H, --HIVES= LIST                Run with hive-LIST defined at ant-hive.xml
	#     -M, --MAP= LIST                  Generates static map(s) for files in LIST
	#     -q, --quiet                      Quiet mode.Only displays errors.
	#     -r, --root_dir= PATH             root directory for Ants
	#     -R, --ROUTE= LIST                Generates dynamic route(s) for "target@file" in LIST
	class Options ;end

	
	#== About 'ant-hive.xml'
	#ant-hive.(rb|exe) �ׂ̗ɂ́Aant-hive.xml �����݂��邱�ƂƎv���܂��B
	#����XML�t�H�[�}�b�g�̍\���t�@�C���ɂ́A���Ȃ����T������hive�̏���ۊǂ��Ă��������B
	#hive����ۊǂ��邱�ƂŁA���Ƃ��牽�x�ł�����̒T�����s�����Ƃ��\�ƂȂ�܂��B
	#�܂��A-r�I�v�V����+(-M -R)�I�v�V�����ł́A�w�肷�邱�Ƃ̏o���Ȃ��������s���v���p�e�B������ant-hive.xml��
	#�p���邱�ƂŎw�肷�邱�Ƃ��\�ł��B
	#Author��ant-hive��-H�I�v�V�����Ŏg�p���邱�̕��@�������Ƃ��g���₷���̂ł͂Ȃ����ƍl���Ă��܂��B
	#
	#=== Elements of 'ant-hive.xml'
	#ant-hive.xml�ɂ͓��iDTD��������`����Ă��܂���B����قǓ�����̂ł͂Ȃ�����ł��B
	#���̍\���t�@�C����root�v�f�́Aanthive�ł��B
	#
	#- anthive�v�f�̎q�v�f�́Ahive �v�f�݂̂ł��B1��hive�����Ȃ��̒T��������1�̑���\�����Ă��܂��B
	#  - hive�v�f�ɂ͑����Ƃ��� name �������w�肷��K�v������܂��B
	#    hive��name�����������A�R�}���h���C������ant-hive -H ����͂�����ɑ�����ׂ����O�ł��B
	#
	#- hive�v�f�́A�q�v�f�Ƃ���root_directory�v�f�Amap�v�f�Aroute�v�f���������܂��B
	#  - root_directory�v�f��1 hive�ɂ�1�K�v�ł��B
	#    path�����ŁA��͂��ׂ�ant(*.xml)��֘A����v���p�e�B(*.properties)�̎��s���c���[��ۊǂ����f�B���N�g�����A
	#    ant-hive����̑��΃p�X�Ŏw�肵�Ă��������B�R���͕K�{�̑����ł��B
	#  - map�v�f��1 hive�ɂ�0�`N ��`�ł��܂��B
	#    file�����ŐÓI��͏����o�͂�����ant���w�肵�Ă��������B�Ȃ��Afile�����Ŏw�肷��ۂɂ́A
	#    root_directory�v�f�Ŏw�肵��path����̑��΃p�X�Ŏw�肵�Ă��������B
	#  - route�v�f��1 hive�ɂ�0�`N ��`�ł��܂��B
	#    route�v�f��3�̑������������܂��B
	#    [file����] ���I�o�H�����o�͂�����ant���w�肵�Ă��������Broute�v�f���L�q����ۂɂ͂��̑����͕K�{�ł��B
	#    [target����] file�����Ŏw�肵��ant�́A�ŏ��Ɏ��s���ׂ�target���w�肵�Ă��������B
	#                 ���̑��������ݒ�̏ꍇ�ɂ́A�o�H�]�����s��ant�̂Ȃ���default�Ŏw�肳�ꂽtarget�𓮓I�]���̊J�n�_�Ƃ��܂��B
	#    [options����] ���I�o�H��͂�����ۂɗ^����I�v�V�������w�肵�Ă��������B
	#                  �������ł̓v���p�e�B��ݒ肷�邱��(-D����)�����o���܂���B
	#                  ����̎����ł����̑��̃I�v�V�����𗝉��ł���悤�ɂ͂Ȃ�Ȃ��ł��傤�B;-)
	#                  �w��̕��@�́Akey=val �ł��B�����̃v���p�e�B���w�肷��ɂ́Akey=val �̃Z�b�g���J���}�Őڑ����Ă��������B
	#
	#=== Insight 'ant-hive.xml'
	#�ŏ���ant-hive.xml�͂��̂悤�ɂȂ��Ă���Ǝv���܂��B
	#  :include: ant-hive.xml.sample
	#
	#���̕��ɁA<hive name="sample"> �v�f��������`����Ă���̂ŁA���̎��_�ł�ant-hive -H sample �݂̂�
	#�g�p�\�Ȓ�`���ł��B
	#����hive�v�f�ɂ́A�ȉ��̎q�m�[�h����`����Ă��܂��B
	#[root_directory path="sample"]
	#   ����́Aant-hive�����݂���f�B���N�g����sample�f�B���N�g�������݂��A
	#   ���̃f�B���N�g�������z�I�ȃ��[�g�f�B���N�g���Ƃ��邱�Ƃ��w�肵�Ă��܂��B
	#   ���̉��z���[�g�f�B���N�g���ȉ��ɁA�c���[�\�����ێ������܂�ant�t�@�C���ƃv���p�e�B�t�@�C���ނ��z�u����Ă���Ƒz�肵�܂��B
	#
	#[map file="build.xml"]
	#   �����build.xml�t�@�C���̐ÓI�\�����o�͂��邱�Ƃ��w�����Ă��܂��B
	#   �������Aroot_directory�Ŏw�肳�ꂽ�f�B���N�g������̑��΃p�X�ł��邱�Ƃ����Y��Ȃ��B
	#   ���̗�ł́A���ۂɂ�`PWD`/sample/build.xml �t�@�C���̉�͂��s�����Ƃ��w�肵�Ă��܂��B
	#
	#[route file="build.xml" target="release"]
	#   �����build.xml�t�@�C����release�^�[�Q�b�g���J�n�_�Ƃ��ē��I�o�H��]�����邱�Ƃ��w�����Ă��܂��B
	#   map�v�f�Ɠ��l�ɁAbuild.xml�̎��ۂ̃p�X��`PWD`/sample/build.xml �ƂȂ�܂��B
	#
	#[route file="build.xml" target="generate_exe"]
	#   �����build.xml�t�@�C����generate_exe...(�ȉ�����)�B
	#
	#�����̒�`����Aant-hive -H sample �����s�����Ƃ��ɂ́A�ȉ��̂悤�ȋ����������܂��B
	#1. `PWD`/sample/build.xml �̐ÓI��͂����{���܂��B
	#2. ���ɁA`PWD`/sample/build.xml ��release�^�[�Q�b�g���J�n�_�Ƃ��āA
	#   ���ɃI�v�V�������w�肳��Ă��Ȃ����̂Ƃ��ē��I�o�H����]�����܂��B
	#   ����́A����build.xml����͂���Ă���̂ōĉ�͎͂��{���܂��񂪁A�܂���͂���Ă��Ȃ��t�@�C�����w�肳�ꂽ
	#   �ꍇ�ɂ́A��͏����������Ŏ��{����܂��B
	#3. ���ɁA`PWD`/sample/build.xml ��generate_exe�^�[�Q�b�g���J�n�_�Ƃ���...(�ȉ�����)�B
	#
	#���I�o�H�]���̉ߒ��ő���ant�t�@�C���ɐ��䂪�ڂ�悤�ȏꍇ�ɂ́A�K�v�ɉ����čĉ�͂����{����܂��B
	#�������A�ÓI�\�����o�͂���邱�Ƃ��ۏႳ���̂́Amap�I�v�V�����Ŏw�肵�Ă���ꍇ�Ɍ����邱�Ƃ�Y��Ȃ��ł��������B
	class AntHiveConfigFile; end

	#== Add New Hives
	#�����܂łŁA�܂��G��Ă��Ȃ����������Ƃ��d�v�ȓ_�B
	#�u�ǂ�����ĉ���ant�B����͂���񂾂��I�v�Ƃ����˂����݂ɑ΂���񓚂��A���̕����ŋL�q���܂��B
	#
	#�K�v�ȃX�e�b�v�́A�P����1�X�e�b�v�݂̂ł��B
	#- ��͂�����Ant�B�̎��s���f�B���N�g���E�c���[�S�̂��Aant-hive�̔C�ӂ̃f�B���N�g���ɔz�u����
	#�݂̂ł��B
	#
	#�Ⴆ�΁Aant�̎��s�����ȉ��̂悤�ɂȂ��Ă���ꍇ(���̗�͂������K���ł��B)
	# build.serv.pjt1:/
	#   var/
	#     ant/
	#       cvs.properties
	#   release-tools/
	#     ants/
	#       build.xml
	#       buildApp.xml
	#       buildDoc.xml
	#       common/
	#         cvs.xml
	#         compile.xml
	#       tmp/
	#         checkout/
	#           infos/
	#             info.properties
	#�r���h�X�N���v�g�̎��s���ł���A/release-tools/�ȉ��S�ĂƁA/var/ant/cvs.properties���܂Ƃ߂Ď����Ă��āA
	#�K�X�̖���(�����ł�my_root�Ƃ���)�̃f�B���N�g����ant-hive�ȉ��ɍ쐬���A�˂����݂܂��B
	# C:\hoge
	#     \ant-hive
	#       \doc
	#       \generators
	#       \sample
	#       \ant-hive.exe
	#       \ant-hive.xml
	#       \my_root       <------ ���������z�I��root�Ƃ��āA�֘A����t�@�C���Q��
	#         \var                 �f�B���N�g���c���[���ێ������܂܂ŃR�s�[����B
	#           \ant
	#             \cvs.properties
	#         \release-tools
	#           \ants
	#             \build.xml
	#             \buildApp.xml
	#             \buildDoc.xml
	#             \common
	#               \cvs.xml
	#               \compile.xml
	#             \tmp
	#               \checkout
	#                 \infos
	#                   \info.properties
	#
	#�{���́A�V�X�e����̔C�ӂ̃f�B���N�g���ɔz�u���邱�Ƃ������悤�ƍl���Ă���̂ł����A�܂��o�O��
	#��肫��Ă��Ȃ��悤�Ȃ̂ŁAant-hive�̃T�u�f�B���N�g���̉������ɂ����Ă��������B
	#
	#�����āAmy_root�����z�̃��[�g�E�f�B���N�g���Ƃ��Ă�������̑��΃p�X�őΏۂ̃t�@�C�����w�肵�Ă��������B
	#���̗�̏ꍇ�ł���΁A
	#- -r+-M,-R �I�v�V�����ŋN������ꍇ
	#  - ant-hive -r my_root -M relase-tools/ants/build.xml
	#
	#- -H�I�v�V�����ŋN������ꍇ
	#  - ant-hive -H my_app
	#  - ant-hive.xml �̒ǉ����e(��)
	#     <hive name="my_app">
	#       <root_directory path="my_root" />
	#       <map file="relase-tools/ants/build.xml" />
	#       <route file="relase-tools/ants/build.xml" target="releaseMyApp" options="cvs.server=cvs.serv.pjt1,build.server=build.serv.pjt1"/>
	#     </hive>
	#
	#=== ���ӎ���
	#ant-hive��ROUTE���𐶐�����ۂɂ́A AntHive::Evaluater ��Ant�X�N���v�g�𒀎����߂��Ȃ��珈�������{���܂��B
	#���̍ۂɁA���z�̃��[�g�f�B���N�g�����ׂ��悤�ȃt�@�C����K�v�Ƃ����ꍇ�ɂ́A��O�𔭐������܂��B
	#(����́A���z�I�ȃ��[�g�f�B���N�g���̊O���ɂ���t�@�C���ɑ΂���A�N�Z�X�͂�����ׂ��ł͖����Ƃ̐݌v��̔��f�ɂ��܂��B)
	#
	#�]���āA��L�̗�ŉ��z���[�g�f�B���N�g����my_root/release-tools/ants �ɐݒ肵���ꍇ�AMAP�����͓��삷�邩�Ǝv���܂����A
	#ROUTE��������/var/ant/cvs.properties���Q�Ƃ��鏈���������Ă���ꍇ�ɂ́A��O�������܂��B
	#������邽�߂ɂ́A��q�̂Ƃ��艼�z�I�ȃ��[�g�f�B���N�g����my_rot�ɐݒ肵�A��������̑��΃p�X�ŁA���߂���Ant�t�@�C�����w�肵�Ă��������B
	class AddNewHives; end
end

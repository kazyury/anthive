#!ruby -Ks

#AntHiveのドキュメントをRdocに組み込むための名前空間です。
module AntHiveDocument

	#== First Step
	#何はともあれ使ってみましょう。anthiveにはsampleを同梱しています。
	#
	#sampleディレクトリの構造は以下のようになっています。
	# sample/
	#   build.xml
	#   VERSION
	#
	#ここで、build.xmlはとあるアプリケーションのリリース用antスクリプトです。
	#VERSIONファイルはプロパティファイルとして使用しています。
	#
	#=== MAP of 'sample/build.xml'.
	#このbuild.xmlの静的な構造を暴いてみましょう。
	#コマンドラインより、以下のように実行してください。(以下、例としてはWin32バイナリ版のant-hive.exeを使用している場合を想定しています。)
	#
	# E:\Home\kz\anthive>ant-hive -r sample -M build.xml
	#
	#以下のようなログがずらずらと表示されて、エラーらしきものが見つからなければOKです。
	# I, [2008-01-27T21:12:03.140000 #996]  INFO -- AntHive::CUI: ant-hive is starting. Log level is [ 1 ].
	# I, [2008-01-27T21:12:04.281000 #996]  INFO -- AntHive::Controller: ========================================
	# I, [2008-01-27T21:12:04.296000 #996]  INFO -- AntHive::Controller: Ant-hive is running with these settings.
	# I, [2008-01-27T21:12:04.296000 #996]  INFO -- AntHive::Controller:      root_directory    : [ sample ]
	# I, [2008-01-27T21:12:04.312000 #996]  INFO -- AntHive::Controller:      request for map   : [ build.xml ]
	# I, [2008-01-27T21:12:04.312000 #996]  INFO -- AntHive::Controller: Starting static-parse for [ sample/build.xml ].
	# I, [2008-01-27T21:12:04.390000 #996]  INFO -- AntHive::Controller: Static map for [ sample/build.xml ] was generated.
	# I, [2008-01-27T21:12:13.046000 #996]  INFO -- AntHive::Controller: [ sample.svg ] was successfully generated as MAP.
	#
	#そしてカレントディレクトリに、sample.dot と sample.svg が出力されている筈です。
	#sample.svgが、buld.xmlの静的構造を示した図です。SVGビューワで表示してみてください。
	#link:sample.png
	#
	#antスクリプト内の各ターゲットは、1つの箱(Node)で表現されます。
	#そして、その箱と箱の間に矢印(Edge)が引かれている場合には、その間に何らかの実行順が存在することを表現しています。
	#凡例は以下のとおりです。
	#- 実線で、矢先が通常の矢印
	#  - sample/build.xmlでは、release から package, releaseからrun_unit_testに引かれている矢印です。
	#  - この矢印は矢元のターゲットから、矢先のターゲットをantcallタスクにより実行していることを表現しています。
	#- 実線で、矢先が白抜きの菱形
	#  - sample/build.xmlでは、release から generate_docsに引かれている矢印です。
	#  - この矢印は矢元のターゲットから、矢先のターゲットをantタスクにより実行していることを表現しています。
	#- 実線で、矢先が白抜きの半菱形
	#  - sample/build.xmlでは、release から generate_exeに引かれている矢印です。
	#  - この矢印は矢元のターゲットから、矢先のターゲットをsubantタスクにより実行していることを表現しています。
	#- 破線で、矢先が通常の矢印
	#  - sample/build.xmlでは、make_recipe から generate_exeに引かれている矢印です。
	#  - この矢印は、矢先(generate_exe)が矢元(make_recipe)に依存しているために、矢元を先に実行してから、
	#    矢先が実行されることを表現しています。
	#    この破線の矢印は、他の実線矢印と異なり、呼出関係を表現しているわけではないことに注意してください。
	#
	#=== ROUTE of 'release' target of 'sample/build.xml'.
	#次に、sample/build.xmlのreleaseターゲットを実行したときに、どのような経路を用いてビルドが行われているのかを
	#確認しましょう。
	#コマンドラインより、以下のように実行してください。
	#
	# E:\Home\kz\anthive>ant-hive -r sample -R "release@build.xml"
	#
	#以下のようなログがずらずらと表示されて、エラーらしきものが見つからなければOKです。
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
	#そして、sampleディレクトリに release_at_build.xls ファイルが作成されていることを確認してください。
	#このファイルはこのようになっているはずです。
	#link:release_at_build.png
	#
	#releaseターゲットからの動的経路を表現するこのROUTEでは、MAPとは異なり、Antスクリプトのどの行がどのタイミングで実行されるかを
	#ある程度の正確さで表現しています。
	#この例では、
	#1. sample/build.xml の releaseターゲットが開始された。(太字のEntering target:release @.....)
	#2. このターゲットで、antcallタスク(target="run_unit_test")が評価される。
	#3. sample/build.xml の run_unit_testターゲットが開始された。
	#4. けど、何もせずにrun_unit_testターゲットを抜けた。(Leaving target:run_unit_test @ .....)
	#   (これは、releaseターゲットに戻ったことになる)
	#5. このターゲット(release)で、antタスク(target="generate_docs")が評価される。
	#6. antタスクでantfileが指定されていないので、デフォルトファイル名のbuild.xmlのgenerate_docsターゲットを開始する。
	#7. <exec dir='${basedir}' executable='rdoc.bat'>が評価された。
	#   このノードには、プロパティ展開を示す${basedir}が存在するので、この時点でのプロパティ値を評価した結果である、
	#   <exec dir='.' executable='rdoc.bat'>を次の行に、参考程度として、青斜体字で追記。
	#8. and so on.
	#等々をこの出力ファイルに表現しています。
	class FirstStep ; end
	
	#== Options.
	#ant-hiveは基本的にはコンソールアプリです。
	#実行時オプションとして、-g 又は --guiを設定するとGUIモードで立ち上がる予定ですが、
	#現Versionでは未実装です。
	#
	#ant-hiveには複数のオプションがありますが、基本的なパターンは限られています。
	#
	#- ant-hive -g
	#  - GUIモードで起動します(未実装)。
	#
	#- ant-hive -H 定義済みhive名
	#  - 同ディレクトリのant-hive.xml内で定義された定義済みhive名を用いて蟻の巣を暴きます。
	#    最も一般的な使用方法です。
	#    sample/build.xmlを暴くためには、ant-hive -H sample としてみてください。
	#
	#- ant-hive -r ant_root -M mapリスト -R routeリスト
	#  - 一回こっきりの作業ならばこれもまた良いでしょう。
	#    sample/build.xmlの全体mapと、releaseターゲットから始まる一連のrouteを暴くには、ant-hive -r sample -M build.xml -R release@build.xml としてみてください。
	#
	#コマンドを実行すると、以下の様にコンソール上にログが出力されます。
	#デフォルトでは、Info, Warn, Error相当のログが出力されます。
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
	#-d, -q オプションはログ出力のレベルを変更します。
	#- -d, --debug デバッグモードです。呆れるほど大量のログを吐いてくれます。
	#- -q, --quiet 静かにするモードです。Error以外にはログを吐きません。ただし、Errorが途中で発生しても出来る限り解析を続けようとします。
	#
	#なお -f, --fake オプション、これらは忘れてください。蟻の巣を暴くには不要なオプションです。
	#これらのオプションは、ant-hive -h で参照することが出来ます。
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
	#ant-hive.(rb|exe) の隣には、ant-hive.xml が存在することと思います。
	#このXMLフォーマットの構成ファイルには、あなたが探索するhiveの情報を保管してください。
	#hive情報を保管することで、あとから何度でも同一の探索を行うことが可能となります。
	#また、-rオプション+(-M -R)オプションでは、指定することの出来なかった実行時プロパティもこのant-hive.xmlを
	#用いることで指定することが可能です。
	#Authorはant-hiveを-Hオプションで使用するこの方法がもっとも使いやすいのではないかと考えています。
	#
	#=== Elements of 'ant-hive.xml'
	#ant-hive.xmlには特段DTDも何も定義されていません。それほど難しいものではないからです。
	#この構成ファイルのroot要素は、anthiveです。
	#
	#- anthive要素の子要素は、hive 要素のみです。1つのhiveがあなたの探索したい1つの巣を表現しています。
	#  - hive要素には属性として name 属性を指定する必要があります。
	#    hiveのname属性こそが、コマンドラインからant-hive -H を入力した後に続けるべき名前です。
	#
	#- hive要素は、子要素としてroot_directory要素、map要素、route要素を持ちえます。
	#  - root_directory要素は1 hiveにつき1つ必要です。
	#    path属性で、解析すべきant(*.xml)や関連するプロパティ(*.properties)の実行時ツリーを保管したディレクトリを、
	#    ant-hiveからの相対パスで指定してください。コレは必須の属性です。
	#  - map要素は1 hiveにつき0～N 個定義できます。
	#    file属性で静的解析情報を出力したいantを指定してください。なお、file属性で指定する際には、
	#    root_directory要素で指定したpathからの相対パスで指定してください。
	#  - route要素は1 hiveにつき0～N 個定義できます。
	#    route要素は3つの属性を持ちえます。
	#    [file属性] 動的経路情報を出力したいantを指定してください。route要素を記述する際にはこの属性は必須です。
	#    [target属性] file属性で指定したantの、最初に実行すべきtargetを指定してください。
	#                 この属性が未設定の場合には、経路評価を行うantのなかでdefaultで指定されたtargetを動的評価の開始点とします。
	#    [options属性] 動的経路解析をする際に与えるオプションを指定してください。
	#                  現実装ではプロパティを設定すること(-D相当)しか出来ません。
	#                  今後の実装でもその他のオプションを理解できるようにはならないでしょう。;-)
	#                  指定の方法は、key=val です。複数のプロパティを指定するには、key=val のセットをカンマで接続してください。
	#
	#=== Insight 'ant-hive.xml'
	#最初のant-hive.xmlはこのようになっていると思います。
	#  :include: ant-hive.xml.sample
	#
	#下の方に、<hive name="sample"> 要素だけが定義されているので、この時点ではant-hive -H sample のみが
	#使用可能な定義情報です。
	#このhive要素には、以下の子ノードが定義されています。
	#[root_directory path="sample"]
	#   これは、ant-hiveが存在するディレクトリにsampleディレクトリが存在し、
	#   そのディレクトリを仮想的なルートディレクトリとすることを指定しています。
	#   この仮想ルートディレクトリ以下に、ツリー構造を維持したままantファイルとプロパティファイル類が配置されていると想定します。
	#
	#[map file="build.xml"]
	#   これはbuild.xmlファイルの静的構造を出力することを指示しています。
	#   ただし、root_directoryで指定されたディレクトリからの相対パスであることをお忘れなく。
	#   この例では、実際には`PWD`/sample/build.xml ファイルの解析を行うことを指定しています。
	#
	#[route file="build.xml" target="release"]
	#   これはbuild.xmlファイルのreleaseターゲットを開始点として動的経路を評価することを指示しています。
	#   map要素と同様に、build.xmlの実際のパスは`PWD`/sample/build.xml となります。
	#
	#[route file="build.xml" target="generate_exe"]
	#   これはbuild.xmlファイルのgenerate_exe...(以下同文)。
	#
	#これらの定義から、ant-hive -H sample を実行したときには、以下のような挙動を示します。
	#1. `PWD`/sample/build.xml の静的解析を実施します。
	#2. 次に、`PWD`/sample/build.xml のreleaseターゲットを開始点として、
	#   特にオプションが指定されていないものとして動的経路情報を評価します。
	#   今回は、既にbuild.xmlが解析されているので再解析は実施しませんが、まだ解析されていないファイルが指定された
	#   場合には、解析処理が自動で実施されます。
	#3. 次に、`PWD`/sample/build.xml のgenerate_exeターゲットを開始点として...(以下同文)。
	#
	#動的経路評価の過程で他のantファイルに制御が移るような場合には、必要に応じて再解析が実施されます。
	#ただし、静的構造が出力されることが保障されるのは、mapオプションで指定している場合に限られることを忘れないでください。
	class AntHiveConfigFile; end

	#== Add New Hives
	#ここまでで、まだ触れていなかったもっとも重要な点。
	#「どうやって俺のant達を解析するんだっ！」という突っ込みに対する回答を、この文書で記述します。
	#
	#必要なステップは、単純に1ステップのみです。
	#- 解析したいAnt達の実行時ディレクトリ・ツリー全体を、ant-hiveの任意のディレクトリに配置する
	#のみです。
	#
	#例えば、antの実行環境が以下のようになっている場合(この例はすごく適当です。)
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
	#ビルドスクリプトの実行環境である、/release-tools/以下全てと、/var/ant/cvs.propertiesをまとめて持ってきて、
	#適宜の名称(ここではmy_rootとする)のディレクトリをant-hive以下に作成し、突っ込みます。
	# C:\hoge
	#     \ant-hive
	#       \doc
	#       \generators
	#       \sample
	#       \ant-hive.exe
	#       \ant-hive.xml
	#       \my_root       <------ ここを仮想的なrootとして、関連するファイル群を
	#         \var                 ディレクトリツリーを維持したままでコピーする。
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
	#本当は、システム上の任意のディレクトリに配置することを許可しようと考えているのですが、まだバグが
	#取りきれていないようなので、ant-hiveのサブディレクトリの何処かにおいてください。
	#
	#そして、my_rootを仮想のルート・ディレクトリとしてそこからの相対パスで対象のファイルを指定してください。
	#この例の場合であれば、
	#- -r+-M,-R オプションで起動する場合
	#  - ant-hive -r my_root -M relase-tools/ants/build.xml
	#
	#- -Hオプションで起動する場合
	#  - ant-hive -H my_app
	#  - ant-hive.xml の追加内容(例)
	#     <hive name="my_app">
	#       <root_directory path="my_root" />
	#       <map file="relase-tools/ants/build.xml" />
	#       <route file="relase-tools/ants/build.xml" target="releaseMyApp" options="cvs.server=cvs.serv.pjt1,build.server=build.serv.pjt1"/>
	#     </hive>
	#
	#=== 注意事項
	#ant-hiveがROUTE情報を生成する際には、 AntHive::Evaluater がAntスクリプトを逐次解釈しながら処理を実施します。
	#その際に、仮想のルートディレクトリを跨ぐようなファイルを必要とした場合には、例外を発生させます。
	#(これは、仮想的なルートディレクトリの外側にあるファイルに対するアクセスはさせるべきでは無いとの設計上の判断によります。)
	#
	#従って、上記の例で仮想ルートディレクトリをmy_root/release-tools/ants に設定した場合、MAP生成は動作するかと思いますが、
	#ROUTE生成時に/var/ant/cvs.propertiesを参照する処理が入っている場合には、例外が生じます。
	#回避するためには、上述のとおり仮想的なルートディレクトリをmy_rotに設定し、そこからの相対パスで、解釈するAntファイルを指定してください。
	class AddNewHives; end
end

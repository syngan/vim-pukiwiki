vim-pukiwiki
============

vim-pukiwiki ? A vim client for the PukiWiki 1.4.7 for Japanese.

オリジナルで動作しなかったので少し手をいれた.
オリジナルのライセンスがわからない.
改変版はファイルが落とせなかったので機能の参考に.

- メニュー等日本語でべたに書いているので日本語仕える人専用です.
- 初心者の最初の作品なので生温かい目で見守ってください.
- http://d.hatena.ne.jp/syngan/

==============================================================================
使い方

使用するためには vimrc に |g:pukiwiki_config| を設定する必要があります。

Example >
	" PukiWiki のサイト情報
	let g:pukiwiki_config = {
	\	"LocalWiki" : {
	\		"url" : "http://127.0.0.1/pukiwiki/",
	\		"top" : 'FrontPage',
	\		"encode" : "euc-jp",
	\	},
	\}
<

|:PukiWiki|

として起動し、|g:pukiwiki_config| で指定したサイト名を入力するか、

:PukiWiki "サイト名" 
(:PukiWiki LocalWiki)

などとして起動します。

あとは、
  <CR> でページの移動
  :w でページ更新
  <TAB> で [[ ]] 間をジャンプ

注意事項）
  - undo しすぎると空ファイルになります。
  - 最初の 3 行は変更しないでください。
    ヘッダ部であるとして動作しているので、書き込みが壊れることがあります。

  現在 <CR> でページ遷移出来るのは
        BracketName
        BracketNameのエイリアス
  だけです。InterWikiNameや外部URLには現在対応していません。

==============================================================================

TODO:
  - 凍結/凍結解除機能
  - ドキュメント
  - autoload 化
  - vitalize
    - alice.vim が複数バージョンが存在するときの動作が不定なのでこわい
  - undo 連続しても空まで戻らないようにしたい
  - 履歴, ブックマーク
    - PW_get_back_page() つけたけど, s: 変数なので
      複数ページ同時に開くと壊れる
    - ブックマークは, ページを開く手段さえ用意しておけばいいのかな.
  - オリジナル版では bdelete がいるとかなんとか...
  - undo で空にならないようにできないのか.



オリジナル
  http://vimwiki.net/?scripts%2F10
  20080727版 

改変版
  - d.hatena.ne.jp/ampmmn/20090401/1238536800
  - o 書き込み時に文字化けする現象の修正
  - x ユーザ認証への対応
  - x PukiWiki Plusでのセッションチケットへの対処
  - x 凍結/凍結解除機能
  - o :PukiVimコマンドの拡張
  - x 1ファイル化(alice.vim含む)
  - o Vim7以降でしか動かなくなった(改悪)

x はまだ対応できていない.



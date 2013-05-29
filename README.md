vim-pukiwiki
============

vim-pukiwiki ? A vim client for the PukiWiki 1.4.7 for Japanese.

オリジナルで動作しなかったので少し手をいれた.
オリジナルのライセンスがわからない.
改変版はファイルが落とせなかったので機能の参考に.

- メニュー等日本語でべたに書いているので日本語が使える人専用です.
- 初心者の最初の作品なので生温かい目で見守ってください.
- http://d.hatena.ne.jp/syngan/

==============================================================================
使い方

使用するためには .vimrc に `g:pukiwiki_config` を設定する必要があります。

```vim
	" PukiWiki のサイト情報 "
	let g:pukiwiki_config = {
	\	"LocalWiki" : {
	\		"url" : "http://127.0.0.1/pukiwiki/",
	\		"top" : "FrontPage",
	\	},
	\}
```

`:PukiWiki`

として起動し、`g:pukiwiki_config` で指定したサイト名を入力するか、

`:PukiWiki "サイト名"`
(`:PukiWiki LocalWiki`)

などとして起動します。

あとは、
- `<CR>` でページの移動
- `:w` でページ更新
- `<TAB>` で [[ ]] 間をジャンプ

現在 `<CR>` でページ遷移出来るのは以下の2つだけです。InterWikiNameや外部URLには現在対応していません。
- BracketName
- BracketNameのエイリアス


==============================================================================

* TODO:
  - 凍結/凍結解除機能
  - ドキュメント
  - 履歴をファイルに保存する. 不要か.
  - augroup PukiWikiEdit の扱い. 削除できていない.
  - 日本語ファイル名の添付ファイル

* BUG:
  - S-TAB のキーマップが動作しない.
  - `pukiwiki#fileupload()` 後に保存が成功しないことがある

* オリジナル
  http://vimwiki.net/?scripts%2F10
  20080727版

* 改変版
  - d.hatena.ne.jp/ampmmn/20090401/1238536800
  - o 書き込み時に文字化けする現象の修正
  - x ユーザ認証への対応
  - x PukiWiki Plus でのセッションチケットへの対処
  - x 凍結/凍結解除機能
  - o :PukiVim コマンドの拡張
  - o 1ファイル化(alice.vim含む)

x はまだ対応していない.



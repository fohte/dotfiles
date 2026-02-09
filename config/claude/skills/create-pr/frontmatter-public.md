```yaml
---
title: 'PRタイトル'
steps:
    ready-for-translation: false
    submit: false
---
```

- `title`: PR のタイトル（submit 時に使用される）
- `steps.ready-for-translation`: ドラフト承認フラグ。true になったら翻訳を実行する。public repo では翻訳は**必須**であり、submit 時に日本語が含まれているとエラーになる
- `steps.submit`: true にするとエディタ終了時にファイルのハッシュが保存される。submit 時にハッシュが一致しないと失敗する（改ざん防止）

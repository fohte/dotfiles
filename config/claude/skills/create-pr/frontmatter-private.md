```yaml
---
title: 'PRタイトル'
steps:
    submit: false
---
```

- `title`: PR のタイトル（submit 時に使用される）
- `steps.submit`: true にするとエディタ終了時にファイルのハッシュが保存される。submit 時にハッシュが一致しないと失敗する（改ざん防止）

# karabiner

## JSON 生成手順

```bash
jsonnet config/karabiner/assets/complex_modifications/dvorak.jsonnet | prettier -w --parser json | tee config/karabiner/assets/complex_modifications/dvorak.json
```

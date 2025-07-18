# Claude Notification 開發指南

## TDD (Test-Driven Development) 原則

### 核心原則
1. **測試優先**: 永遠先寫測試，再寫 production code
2. **測試不可變**: 一旦測試通過，除非需求變更，否則不應修改測試
3. **最小實作**: 只寫足夠讓測試通過的最少程式碼

### 開發流程
1. **Red**: 寫一個失敗的測試
2. **Green**: 寫最少的程式碼讓測試通過
3. **Refactor**: 重構程式碼，但保持測試通過

### 資料處理原則
- **保持原始資料結構**: 來源資料的結構必須保持完整
- **資料完整性**: 確保所有原始資料都被保留，不可遺失任何欄位
- **資料轉換**: 若需要轉換資料格式，必須保留原始資料的完整副本

### 測試規範
- 每個功能必須有對應的單元測試
- 測試應該獨立且可重複執行
- 測試命名要清楚描述測試目的
- 使用 Arrange-Act-Assert 模式組織測試

### 專案結構建議
```
claude-notification/
├── src/
│   ├── models/      # 資料模型
│   ├── services/    # 業務邏輯
│   └── utils/       # 工具函數
├── tests/
│   ├── models/      # 模型測試
│   ├── services/    # 服務測試
│   └── utils/       # 工具測試
├── requirements.txt # Python 依賴
└── pytest.ini       # pytest 設定
```

### 命令
- 執行測試: `pytest`
- 執行特定測試: `pytest tests/test_file.py::test_function`
- 查看測試覆蓋率: `pytest --cov=src`
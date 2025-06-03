# PasteMyst CSS 版本參數修復報告

## 問題描述
CSS 檔案加載時出現格式錯誤的版本參數 `?v=fatal:%20No%20names%20found,%20cannot%20describe%20anything.`，而不是正確的版本字串。這個問題是因為 Git 命令 `git describe --tags` 在沒有 Git 標籤的倉庫中失敗，錯誤訊息被 URL 編碼後傳遞給 CSS 檔案造成的。

## 根本原因
在 `source/pastemyst/data/version.d` 檔案中，`getGitVersion()` 函數直接執行 `git describe --tags` 並返回原始輸出，包括錯誤訊息。當倉庫沒有標籤時，這會導致錯誤訊息被用作版本字串。

## 修復方案
修改了 `getGitVersion()` 函數，增加了完整的錯誤處理和回退機制：

### 1. 檢查命令執行狀態
```d
auto res = executeShell("git describe --tags");
if (res.status != 0)
{
    // 處理失敗情況
}
```

### 2. 多層回退機制
- **主要**：嘗試 `git describe --tags`
- **回退1**：如果失敗，使用 `git rev-parse --short HEAD` 生成 `dev-{hash}` 格式
- **回退2**：如果所有 Git 命令都失敗，返回 `"dev-unknown"`

### 3. 輸出清理
使用 `strip()` 清理所有命令輸出中的空白字符。

## 修復前後對比

### 修復前（有問題）
```
版本字串: "fatal: No names found, cannot describe anything."
CSS URL: ?v=fatal:%20No%20names%20found,%20cannot%20describe%20anything.
結果: ❌ CSS 加載失敗
```

### 修復後（正常）
```
有標籤的倉庫:
版本字串: "2.8.3-14-g4712511"
CSS URL: ?v=2.8.3-14-g4712511
結果: ✅ 正常加載

無標籤的倉庫:
版本字串: "dev-4712511" (或 "dev-unknown")
CSS URL: ?v=dev-4712511
結果: ✅ 正常加載
```

## 測試驗證
創建了測試腳本 `test_version_fix.py` 來驗證修復邏輯：
- ✅ 正常情況：返回 `2.8.3-14-g4712511`
- ✅ 回退情況：返回 `dev-4712511`
- ✅ 所有生成的版本字串都是乾淨且可用的

## 修改的檔案
- `source/pastemyst/data/version.d` - 主要修復
- `test_version.d` - 獨立測試腳本
- `test_version_fix.py` - Python 驗證腳本

## 影響
此修復確保：
1. CSS 檔案始終能正常加載
2. 版本控制在所有環境中都能穩定工作
3. 開發環境中沒有 Git 標籤也不會影響應用程式運行
4. 版本字串保持乾淨且有意義

修復已完成並通過測試驗證。

# Scoop app manifest 编写规则

## 参考文件和链接

- app manifest 模板：bucket/app-name.json.template
- scoop wiki 页面：<https://github.com/ScoopInstaller/Scoop/wiki>

若 manifest 模板与 wiki 存在冲突，以 wiki 的描述为准，模板可能没有更新。

## App Manifest

app manifest 本质上是一个 JSON 文件，用于描述如何安装程序。<br/>
写 app manifest 时，尤其要注意持久化文件（`persist` 字段），若没有将例如用户配置这种重要文件持久化，升级后就可能会变成全新安装。所以要尤其注意 app 是否会在其根目录下产生此类文件，如果 app 是开源的，可直接阅读其源码以精确定位。对于不开源的 app，也可以通过其他的技术手段或方法尽量检查。应该让 scoop 尽可能完整地管理 app 的所有文件，有些 app 不仅在其根目录下产生数据，还会在比如 User home 等其他目录下产生数据，这些文件也需要跟踪，使执行 `scoop uninstall -p <app-name>` 或 `scoop uninstall --purge <app-name>` 时能完整删除该 app。

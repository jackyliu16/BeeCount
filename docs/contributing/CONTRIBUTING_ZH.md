# 贡献指南

感谢你考虑为蜜蜂记账做出贡献！🎉

这份指南将帮助你了解如何参与项目开发、报告问题、提交代码等。我们欢迎所有形式的贡献，无论是代码、文档、翻译还是建议。

## 📋 目录

- [行为准则](#行为准则)
- [我能做什么贡献？](#我能做什么贡献)
- [报告 Bug](#报告-bug)
- [提出新功能建议](#提出新功能建议)
- [代码贡献流程](#代码贡献流程)
- [开发环境设置](#开发环境设置)
- [代码规范](#代码规范)
- [提交信息规范](#提交信息规范)
- [Pull Request 流程](#pull-request-流程)
- [翻译贡献](#翻译贡献)
- [文档贡献](#文档贡献)
- [问题和讨论](#问题和讨论)

## 行为准则

### 我们的承诺

为了营造一个开放、友好的环境，我们作为贡献者和维护者承诺：让参与项目和社区的每个人都享有无骚扰的体验，无论其年龄、体型、残疾、种族、性别认同和表达、经验水平、国籍、个人形象、种族、宗教或性取向如何。

### 我们的标准

有助于创造积极环境的行为包括：

- 使用友好和包容的语言
- 尊重不同的观点和经验
- 优雅地接受建设性批评
- 关注对社区最有利的事情
- 对其他社区成员表示同理心

### 执行

不可接受的行为可以通过联系项目团队 sunxiaoyes@outlook.com 来报告。所有投诉都将被审查和调查，并将做出必要且适当的回应。

## 我能做什么贡献？

### 🐛 报告 Bug

发现了问题？请通过 [GitHub Issues](https://github.com/TNT-Likely/BeeCount/issues) 告诉我们。

### 💡 提出新功能

有好的想法？我们很乐意听到！请先查看 [Issues](https://github.com/TNT-Likely/BeeCount/issues) 和 [Discussions](https://github.com/TNT-Likely/BeeCount/discussions) 看看是否已经有人提出。

### 💻 贡献代码

- 修复 Bug
- 实现新功能
- 优化性能
- 重构代码

### 📝 完善文档

- 改进 README
- 补充使用教程
- 添加代码注释
- 编写 Wiki 页面

### 🌍 贡献翻译

帮助我们将应用翻译成更多语言，让更多人能够使用。

### 🎨 设计贡献

- UI/UX 改进建议
- 图标设计
- 截图和宣传素材

#### 🎨 招募设计师 {#designer-recruitment}

**我们正在寻找有才华的 UI/UX 设计师加入蜜蜂记账项目！**

📐 **参与内容：**

- 重新设计应用 UI 和交互体验
- 设计主题皮肤和插画元素
- 优化用户界面的视觉一致性
- 创建现代化、简洁的设计语言

🎁 **你将获得：**

- 开源项目作品集积累
- 在 README 和应用中署名
- 与开发团队密切合作的机会
- 为数千用户打造优质体验的成就感

💌 **联系方式：**

- GitHub Issues: [提交设计建议](https://github.com/TNT-Likely/BeeCount/issues)
- Telegram: [加入讨论群](https://t.me/beecount)

## 报告 Bug

### 提交前检查

在提交 Bug 报告前，请先：

1. 检查 [FAQ](https://github.com/TNT-Likely/BeeCount/wiki/常见问题-FAQ) 看看问题是否已有解决方案
2. 搜索 [现有 Issues](https://github.com/TNT-Likely/BeeCount/issues) 确认问题未被报告
3. 确保你使用的是最新版本

### 如何报告

创建 Issue 时请包含以下信息：

**Bug 描述**
- 简短清晰地描述 Bug
- 预期行为是什么
- 实际发生了什么

**复现步骤**
1. 打开应用
2. 点击 '...'
3. 输入 '...'
4. 看到错误

**环境信息**
- 操作系统：[如 Android 13, iOS 16.5]
- 设备型号：[如 Pixel 7, iPhone 14]
- 应用版本：[如 v0.1.5]
- 云服务配置：[Supabase / WebDAV / 本地模式]

**截图或日志**
如果可以，请提供截图或错误日志。

**示例 Issue**

```markdown
**Bug 描述**
在添加交易时，如果金额超过 6 位数，保存按钮无响应。

**复现步骤**
1. 打开应用，点击 "+" 添加交易
2. 选择任意分类
3. 输入金额 1000000
4. 点击保存按钮
5. 没有任何反应，交易未保存

**预期行为**
应该能够保存大额交易，或者显示金额限制提示。

**环境信息**
- 操作系统：Android 13
- 设备：小米 13
- 应用版本：v0.1.5
- 云服务：本地模式

**截图**
[附上截图]
```

## 提出新功能建议

我们欢迎新功能建议！在提交前：

1. 检查 [Discussions](https://github.com/TNT-Likely/BeeCount/discussions) 中的"Ideas"分类
2. 确认功能符合项目定位（隐私优先、开源、自托管）
3. 考虑功能的实用性和普遍性

### 功能建议模板

```markdown
**功能描述**
简短描述你希望添加的功能。

**使用场景**
描述这个功能解决什么问题，在什么情况下使用。

**建议的实现方式**（可选）
如果你有技术建议，请详细说明。

**替代方案**（可选）
是否考虑过其他解决方案？

**附加信息**
其他相关信息、参考链接或截图。
```

## 代码贡献流程

### 1. Fork 仓库

点击 GitHub 页面右上角的 "Fork" 按钮，将仓库 fork 到你的账号下。

### 2. Clone 到本地

```bash
git clone https://github.com/你的用户名/BeeCount.git
cd BeeCount
```

### 3. 添加上游仓库

```bash
git remote add upstream https://github.com/TNT-Likely/BeeCount.git
```

### 4. 创建功能分支

```bash
git checkout -b feature/your-feature-name
# 或
git checkout -b fix/your-bug-fix
```

分支命名规范：
- `feature/功能名` - 新功能
- `fix/问题描述` - Bug 修复
- `refactor/模块名` - 重构
- `docs/文档名` - 文档更新

### 5. 开发和测试

- 遵循[代码规范](#代码规范)
- 编写必要的注释
- 测试你的更改

### 6. 提交更改

```bash
git add .
git commit -m "feat: 添加某个功能"
```

遵循[提交信息规范](#提交信息规范)。

### 7. 同步上游更改

```bash
git fetch upstream
git rebase upstream/main
```

### 8. 推送到你的 Fork

```bash
git push origin feature/your-feature-name
```

### 9. 创建 Pull Request

1. 访问你的 Fork 仓库页面
2. 点击 "Compare & pull request"
3. 填写 PR 描述（见[下文](#pull-request-流程)）
4. 提交 PR

## 开发环境设置

### 系统要求

- **Flutter SDK**: 3.27.3（由 FVM 管理，版本锁定在根目录 `.fvmrc`）
- **Dart SDK**: 3.6.1（随 Flutter 3.27.3 提供，无需单独安装）
- **FVM**: 必装，见下方安装步骤
- **IDE**: VS Code 或 Android Studio（推荐安装 Flutter 插件）
- **操作系统**: macOS, Linux, 或 Windows

### 安装步骤

1. **安装 FVM**

本项目使用 [FVM](https://fvm.app) 锁定 Flutter 版本，请勿直接依赖全局 Flutter SDK。

```bash
dart pub global activate fvm
```

2. **Clone 项目并锁定 SDK**

```bash
git clone https://github.com/TNT-Likely/BeeCount.git
cd BeeCount

# 按 .fvmrc 安装并锁定项目 Flutter SDK
fvm use

# 验证
fvm flutter doctor
```

3. **安装依赖**

```bash
fvm flutter pub get
```

4. **运行代码生成**

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

5. **运行应用**

```bash
# Android
fvm flutter run --flavor dev -d android

# iOS
fvm flutter run -d ios
```

**注意**: 云服务配置通过应用内 UI 完成（个人中心 → 云服务），无需配置文件。

### 使用 Nix 开发环境（可选）

仓库提供 `flake.nix`，为 NixOS / Nix 用户提供**可复现的开发工具链**，并可构建与 `.fvmrc` 精确一致（Flutter 3.27.3）的**密封校验**。`.fvmrc` 始终是 Flutter 版本的唯一事实来源。

```bash
# 进入开发 shell（FVM + JDK17 + Android SDK/NDK + Python 等）
nix develop

# 首次仍需用 FVM 按 .fvmrc 安装 SDK（NixOS 默认跑不起来，见下方「NixOS 注意」）
fvm install && fvm flutter pub get
```

密封层（不依赖本机 Flutter；首次评估需联网抓取 pub 依赖，其后走 Nix store）：

```bash
nix run  .#flutter -- --version           # 密封 Flutter 3.27.3
nix run  .#flutter -- pub get             # 生成 .dart_tool/package_config.json（给下面的运行器用）
nix run  .#flutter-test -- test/utils     # 密封 flutter test：目录/单文件/单用例（-n '用例名'）
nix build .#test                          # 全量密封测试门禁：根 test/ + packages/flutter_cloud_sync{,_supabase}/test
nix build .#test-agentcore                # 纯 Dart 包 packages/agentcore（自带 pubspec.lock + dart test）
nix build .#analyze                       # 密封 flutter analyze（只对 error 设门禁，范围 lib/ + test/）
nix build .#test-webdav                   # 已知红灯：packages/flutter_cloud_sync_webdav/test 有 5 个陈旧用例
nix flake check                           # Nix 层门禁（密封 test + test-agentcore）
```

说明：

- **NixOS 注意**：`fvm` 下载的是通用 Linux 构建，而 NixOS 按设计不提供 FHS 动态链接器（`/lib64/ld-linux-x86-64.so.2` 是只会报错的 stub），所以上面的 `fvm flutter pub get` 默认会失败（`nix develop` 的 shellHook 也会提示）。两条出路：① 不用 FVM，直接走密封入口 `nix run .#flutter -- pub get`；② 在系统配置启用 `programs.nix-ld.enable = true`（按需补 `stdenv.cc.cc.lib` 等库）并重新登录，让 FVM 的 SDK 能运行。另外 `flutter test` 里的 drift/sqlite 用例运行期要 dlopen `libsqlite3.so`，请用 `nix run .#flutter-test`（包装器已设好 `LD_LIBRARY_PATH`）。
- `nix build .#test` 与 `test-agentcore` 都是 `nix flake check` 的一部分，改 `lib/**`、`test/**`、`packages/**` 会在 CI 的 Nix workflow 里跑。
- `analyze` 暂不入门禁：仓库还有约 600 条 info/warning lint 债，且密封环境下对 `packages/**` 做跨包分析会因 pub2nix 把 path 依赖装成独立 store 包而产生类型 identity 伪错误，故只对 `lib/` + `test/` 的 **error** 设门禁。
- `packages/flutter_cloud_sync_webdav/test` 的 5 个用例仍在断言旧的邮箱登录行为，实现已改为抛 `UnsupportedError`；对齐前它们不进 CI 门禁。

#### Linux 桌面预览（可选；非支援平台）

Linux 桌面只用于 **UI smoke / 开发预览**，不是支援平台。日常验证的主力仍然是 `nix flake check`
里的密封 `flutter test`（headless，不需要显示器，也不需要 `linux/` 目录）。

```bash
nix build .#linux              # Linux 桌面 debug 预览（最快）
nix build .#linux-release      # Linux 桌面 release 产物（AOT）
nix run   .#linux-run          # 真实桌面启动 debug 预览（需要显示器/GPU）
nix run   .#linux-smoke        # 无头 UI smoke：Weston headless + 软件 GL（llvmpipe），不需要显示器/GPU
nix develop .#linux            # 互动开发：flutter pub get && flutter run -d linux
```

说明：

- **不入门禁**：`.#linux*` 与 `.#linux-smoke` 都不在 `nix flake check` / CI 里，避免把 native 建置时间与平台差异噪声带进门禁。
- **不是支援平台**：没有 Linux 实作的插件（`permission_handler`、`local_auth`、`webview_flutter`、`gal`、`image_cropper`、`flutter_image_compress`、`in_app_review`、`quick_actions`、`open_filex`、`home_widget`、`in_app_purchase_storekit` …）在运行期会丢 `MissingPluginException`；启动路径大多已 try/catch，实测只有 `home_widget` 会打印警告。
- **GL 由 bundle 自带**：`nix build` 出来的 bundle 只带 GTK、不带 GL 驱动；而宿主 `/run/opengl-driver` 的 mesa 与密封 bundle 的 glibc ABI 不一致（实测加载失败），裸跑会报「没有可用的 GL 实现」。所以 `nix/linux.nix` 把同一个 nixpkgs 实例的 mesa + libglvnd 放进 `runtimeDependencies`，并将 `LIBGL_DRIVERS_PATH` / `__EGL_VENDOR_LIBRARY_DIRS` / `LIBGLX_VENDOR_LIBRARY_NAME` 写进 run wrapper。预览目标固定用 mesa，NVIDIA 闭源驱动不在覆盖范围。`.#linux-smoke` 只是在此外加班 Weston headless + `LIBGL_ALWAYS_SOFTWARE=1`（无头确定性）。
- **预览视窗尺寸**：视窗按手机逻辑尺寸（dp）开，预设依序取 390x844（现代主流）/ 360x780（Android 最常见宽度）/ 320x568（保底），挑第一个能放进当前显示器工作区的——`linux/runner/my_application.cc` 的视窗尺寸就是 Flutter 视口尺寸（Linux embedder 拿 GTK allocation 当逻辑尺寸），所以不能靠放大视窗来「放大画面」。想临时换尺寸（例如 412x915）用 `BEECOUNT_PREVIEW_SIZE=412x915 nix run .#linux-run`；启动日志会印出实际视口 dp（`[preview] Flutter 视口 390 x 844 dp`），拉伸视窗时同步更新。要在 HiDPI 屏上看得更大又不改布局，用 `GDK_SCALE=2`（Flutter 的 pixel_ratio 取 GTK 缩放因子，逻辑尺寸不变）。
- **离线 sqlite**：`sqlite3_flutter_libs` 的 linux 外挂用 CMake `FetchContent` 从网络下载 sqlite3，而 Nix sandbox 无网。`nix/linux.nix` 用 `pkgsFlutter.sqlite.src` 解出 amalgamation 源并通过 `BEECOUNT_SQLITE3_SOURCE_DIR` 传给 `linux/CMakeLists.txt` 覆写来源；非 Nix 环境未设该变量时维持原本下载行为。

**升级 Flutter 版本**：改 `.fvmrc` 后需同步生成密封数据，否则 flake 评估会报错：

```bash
nix/gen-flutter-version.sh <版本>   # 例如 3.27.3，需联网
git add nix/flutter-versions/<版本>.json
```

### 项目结构

```
lib/
├── data/              # 数据层
│   ├── db.dart       # 数据库定义
│   ├── models/       # 数据模型
│   └── repository.dart # 数据仓库
├── pages/            # UI 页面
│   ├── home/         # 首页
│   ├── charts/       # 图表页
│   ├── ledgers/      # 账本页
│   └── mine/         # 个人中心
├── widgets/          # 通用组件
│   ├── ui/           # UI 基础组件
│   └── biz/          # 业务组件
├── cloud/            # 云服务
│   ├── supabase_auth.dart
│   └── supabase_sync.dart
├── l10n/             # 国际化资源
├── providers.dart    # Riverpod 状态管理
├── styles/           # 主题样式
└── utils/            # 工具函数
```

### 常用命令

```bash
# 运行测试
fvm flutter test

# 代码格式化
fvm dart format .

# 静态分析
fvm flutter analyze

# 构建 APK
fvm flutter build apk --flavor prod --release

# 重新生成代码
fvm dart run build_runner build --delete-conflicting-outputs

# 监听文件变化自动生成
fvm dart run build_runner watch
```

## 代码规范

### 桌面小组件

新增或修改 iOS/Android 桌面小组件前，请遵循[桌面小组件开发规范](HOME_WIDGETS_ZH.md)。其中包含离屏渲染约束、双端预览资源、自动化测试和模拟器验收清单。

### Dart 代码风格

遵循 [Effective Dart](https://dart.dev/guides/language/effective-dart) 规范：

1. **命名规范**
   - 类名：`PascalCase`
   - 函数/变量：`camelCase`
   - 常量：`lowerCamelCase`（Dart 惯例）
   - 私有成员：以 `_` 开头

2. **格式化**
   - 使用 `fvm dart format` 自动格式化
   - 行宽限制 80 字符
   - 使用 2 空格缩进

3. **注释**
   - 公共 API 使用 `///` 文档注释
   - 复杂逻辑添加行内注释
   - 避免无意义的注释

```dart
/// 计算指定月份的收支总额
///
/// [ledgerId] 账本ID
/// [year] 年份
/// [month] 月份（1-12）
/// 返回包含收入和支出的Map
Future<Map<String, double>> calculateMonthlyTotal(
  int ledgerId,
  int year,
  int month,
) async {
  // 实现...
}
```

4. **空安全**
   - 充分利用 Dart 的空安全特性
   - 避免使用 `!` 强制解包，使用 `?.` 和 `??`
   - 函数参数使用 `required` 或提供默认值

### Flutter 组件规范

1. **Widget 结构**
   - 优先使用 `const` 构造函数
   - 将大型 Widget 拆分为小组件
   - 使用 `build` 方法返回单一 Widget

2. **状态管理**
   - 使用 Riverpod 管理状态
   - Provider 命名以 `Provider` 结尾
   - 避免在 Widget 中直接操作数据库

```dart
final ledgersProvider = FutureProvider<List<Ledger>>((ref) async {
  final repo = ref.watch(repositoryProvider);
  return repo.getAllLedgers();
});
```

3. **性能优化**
   - 使用 `const` Widget
   - 避免在 `build` 方法中创建新对象
   - 合理使用 `ListView.builder`

### 数据库规范

1. **Drift 表定义**
   - 表名使用复数（`Transactions`, `Categories`）
   - 字段名使用 camelCase
   - 添加必要的索引

```dart
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ledgerId => integer().references(Ledgers, #id)();
  TextColumn get description => text().nullable()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
```

2. **查询优化**
   - 使用索引加速查询
   - 避免 N+1 查询
   - 使用流式查询响应数据变化

## 提交信息规范

我们使用与 [commitlint](https://commitlint.js.org/) 兼容的 [约定式提交](https://www.conventionalcommits.org/zh-hans/) 规范，**提交信息与 PR 标题均须使用中文**。

### 格式

```
<类型>(<范围>): <简短描述>

[可选的详细描述]

[可选的脚注]
```

### 类型

- `feat`: 新功能
- `fix`: Bug 修复
- `refactor`: 代码重构（不改变功能）
- `style`: 代码格式调整（不影响功能）
- `perf`: 性能优化
- `test`: 添加或修改测试
- `docs`: 文档更新
- `chore`: 构建过程或辅助工具的变动
- `ci`: CI/CD 配置修改
- `revert`: 回滚之前的提交

### 范围

范围用于指出变更所属模块；无明确模块时可省略。常用范围包括：

- `ai`、`cloud`、`sync`、`data`、`ui`、`i18n`
- `docs`、`ci`、`deps`、`release`、`repo`

### 示例

```bash
# 新功能
git commit -m "feat(budget): 添加预算功能"

# Bug 修复
git commit -m "fix(sync): 修复云同步时数据丢失的问题"

# 带详细描述
git commit -m "refactor(data): 重构数据库查询逻辑

- 优化索引使用
- 减少冗余查询
- 提升查询性能约 30%"

# 文档更新
git commit -m "docs(cloud): 更新 Supabase 配置文档"

# 性能优化
git commit -m "perf(home): 优化首页列表渲染性能"
```

### 注意事项

- 使用中文描述
- 简短描述不超过 50 字符
- 使用祈使句（"添加"而非"添加了"）
- 详细描述说明"为什么"而非"是什么"
- 标题使用 `type(scope): subject`；没有合适范围时可使用 `type: subject`
- subject 后不加句号、感叹号等结尾标点

## Pull Request 流程

### PR 标题

必须与 commitlint 兼容，并遵循与提交信息相同的完整格式；Squash merge 后会以该标题作为合并提交标题。例如：
- `feat(currency): 添加多币种支持`
- `fix(sync): 修复 WebDAV 同步失败`

不要使用 `更新代码`、`修复问题`、`AI助手体验升级` 这类缺少 type 的标题。

### PR 描述模板

```markdown
## 变更类型
- [ ] 新功能
- [ ] Bug 修复
- [ ] 文档更新
- [ ] 代码重构
- [ ] 性能优化
- [ ] 其他

## 变更说明
简要描述这个 PR 做了什么。

## 相关 Issue
Closes #123

## 测试情况
- [ ] 已在 Android 上测试
- [ ] 已在 iOS 上测试
- [ ] 添加了单元测试
- [ ] 添加了集成测试

## 截图（如适用）
[附上截图或 GIF]

## 检查清单
- [ ] 代码遵循项目规范
- [ ] 已运行 `fvm dart format` 格式化代码
- [ ] 已运行 `fvm flutter analyze` 无警告
- [ ] 已更新相关文档
- [ ] 提交信息符合规范
```

### 审核流程

1. **自动检查**
   - CI/CD 构建通过
   - 代码格式检查通过
   - 静态分析无错误

2. **代码审查**
   - 维护者会审查你的代码
   - 可能会要求修改
   - 请及时回复评论

3. **合并**
   - 审查通过后会被合并
   - 你的贡献会出现在下一个版本中

### PR 最佳实践

- **保持 PR 小而专注**：一个 PR 只做一件事
- **及时更新**：与主分支保持同步
- **响应评论**：积极回复审查意见
- **完善测试**：确保新功能有足够的测试覆盖
- **更新文档**：功能变更要同步更新文档

## 翻译贡献

蜜蜂记账官方维护 3 种语言（简体中文、繁体中文、English），并接受社区贡献的其他语言翻译。欢迎贡献新语言或改进现有翻译。

### 当前支持的语言

**官方维护：**

- 简体中文 (zh)
- 繁体中文 (zh_Hant)
- English (en)

**社区贡献：**

- 한국어 / 韩语 (ko)

### 添加新语言

1. **创建翻译文件**

在 `lib/l10n/` 目录下创建新的 `.arb` 文件：

```
lib/l10n/app_<语言代码>.arb
```

例如添加意大利语：
```
lib/l10n/app_it.arb
```

2. **复制模板**

复制 `app_en.arb` 的内容，翻译所有字符串：

```json
{
  "appName": "BeeCount",
  "home": "Casa",
  "charts": "Grafici",
  "ledgers": "Conti",
  "mine": "Mio",
  ...
}
```

3. **测试翻译**

```bash
fvm flutter pub get
fvm flutter run
```

在应用设置中切换到新语言，检查翻译效果。

4. **提交 PR**

```bash
git add lib/l10n/app_it.arb
git commit -m "feat: 添加意大利语翻译"
git push origin feature/add-italian-translation
```

### 改进现有翻译

如果发现翻译错误或可以改进的地方：

1. 编辑对应的 `.arb` 文件
2. 提交 PR，说明修改原因

## 文档贡献

### 文档类型

1. **README**: 项目介绍和快速开始
2. **Wiki**: 详细使用教程
3. **代码注释**: API 文档
4. **贡献指南**: 本文档

### 文档规范

1. **语言**
   - README 提供中英双语版本
   - Wiki 主要使用中文
   - 代码注释使用中文

2. **格式**
   - 使用 Markdown 格式
   - 遵循 [Markdown 风格指南](https://google.github.io/styleguide/docguide/style.html)
   - 添加目录和章节链接

3. **内容**
   - 清晰简洁
   - 提供示例代码
   - 添加截图说明
   - 保持更新

### 更新文档

发现文档问题或需要补充？

1. Fork 仓库
2. 编辑文档文件
3. 提交 PR

示例：
```bash
git checkout -b docs/improve-supabase-guide
# 编辑文档
git commit -m "docs: 完善 Supabase 配置说明"
git push origin docs/improve-supabase-guide
```

## 问题和讨论

### 何时使用 Issues

- 报告 Bug
- 提出功能请求
- 询问特定的技术问题

### 何时使用 Discussions

- 一般性讨论
- 分享使用经验
- 寻求帮助
- 头脑风暴

### 社区交流

- [GitHub Discussions](https://github.com/TNT-Likely/BeeCount/discussions) - 项目讨论
- [V2EX 帖子](https://www.v2ex.com/t/1168480) - 中文社区
- Email: sunxiaoyes@outlook.com - 直接联系

## 认可贡献者

所有贡献者都会被记录在项目的贡献者列表中。重大贡献会在 Release Notes 中特别感谢。

## 许可证与贡献者许可条款

本项目采用「个人免费、商业付费」的双许可模式（见 [LICENSE](../../LICENSE)）。通过提交贡献（代码/翻译/文档等），你同意根目录 [CONTRIBUTING.md 中的贡献者许可条款](../../CONTRIBUTING.md#贡献者许可条款contributor-license-terms)：你的贡献以仓库 LICENSE 授权，同时授予项目维护者含商业许可在内的再许可权利；你保留自己贡献的著作权。

---

再次感谢你的贡献！🙏

如有任何问题，欢迎通过 [Issues](https://github.com/TNT-Likely/BeeCount/issues) 或 [Discussions](https://github.com/TNT-Likely/BeeCount/discussions) 与我们联系。

# 《字此一次》Cline 开发规则与计划

> **基于项目文档 v0.5 | Godot 4.6 | VSCode + Cline (DeepSeek)**

---

## 一、核心开发原则

### 1.1 架构约束
- **信号驱动**：所有 UI 更新必须通过 `sentence_updated` 信号触发，不得直接操作 UI 节点。
- **资源分离**：逻辑代码（`scripts/`）与场景配置（`resources/`）严格分离，所有配置数据通过 `@export` 在编辑器中挂载。
- **强类型优先**：所有变量和方法参数必须声明类型，禁止使用 `var` 无类型声明（Godot 4 特性）。

### 1.2 文件命名规范
| 类型 | 命名规则 | 示例 |
|------|----------|------|
| 脚本文件 | `snake_case.gd` | `battle_manager.gd` |
| 场景文件 | `snake_case.tscn` | `battle_xufuji.tscn` |
| 资源文件 | `snake_case.tres` | `enemy_config_lv1.tres` |
| 关卡资源目录 | `lv{N}_words/` | `lv1_words/` |

### 1.3 代码风格
- 缩进：4 空格（Godot 默认）
- 方法命名：`snake_case`
- 信号命名：`snake_case`（如 `sentence_updated`）
- 枚举命名：`PascalCase`（如 `EffectType.MODIFY_ATTRIBUTE`）
- 常量：`SCREAMING_SNAKE_CASE`

---

## 二、关卡开发流程

### 2.1 新增关卡步骤
```
1. 创建资源文件
   ├── resources/lv{N}_words/          # 存放该关卡所有 WordData
   ├── resources/enemy_sentence_lv{N}.tres  # 敌人句子配置
   ├── resources/player_sentence_lv{N}.tres # 玩家句子配置
   ├── resources/enemy_config_lv{N}.tres    # 敌人属性配置
   └── resources/player_config_lv{N}.tres   # 玩家属性配置

2. 创建场景
   ├── scenes/battle_lv{N}.tscn        # 复制 battle_xufuji.tscn 修改
   └── 挂载对应资源文件到场景节点

3. 编写/复用战斗逻辑
   ├── 教学关（一次射击）→ 继承/复用 battle_manager_level2.gd
   └── 完整战斗（回合制）→ 继承/复用 battle_manager.gd

4. 注册关卡跳转
   └── 在上一关的 next_level_scene 属性中指向新场景
```

### 2.2 关键检查清单
- [ ] 敌我句子长度是否相等（`enemy_sentence.size() == player_words.size()`）
- [ ] `shots_allowed` 是否已配置（教学关=1，完整战斗=1）
- [ ] 所有 `WordData` 的 `can_be_shot` 是否正确标记
- [ ] 场景节点名称是否与脚本中引用的 `@onready` 变量名一致
- [ ] `BulletScene` 引用是否已拖入场景（仅第二关）
- [ ] 信号连接是否完整（`sentence_updated` → `SentenceUI.refresh_display()`）

---

## 三、战斗系统扩展规则

### 3.1 新增效果类型
若需在 `EffectData` 中添加新效果类型：
1. 在 `effect_data.gd` 的 `EffectType` 枚举中添加新类型
2. 在 `battle_manager.gd` 的 `apply_effect()` 中添加对应处理分支
3. 在 `effect_data.gd` 中添加对应的 `@export` 属性（如有需要）

### 3.2 新增玩家动作
若需添加新动作（如防御、使用道具）：
1. 在场景 `ActionButtons` 中添加对应按钮
2. 在 `BattleManager` 中添加对应方法（如 `player_defend()`）
3. 在回合状态机中注册新动作（`PLAYER_TURN` 状态下可调用）
4. 动作完成后切换到 `ENEMY_TURN`

### 3.3 子弹系统扩展
`bullet.gd` 支持以下可配置属性：
- `damage`：伤害值
- `direction`：飞行方向（`Vector2`）
- `ricochet`：是否反弹（`bool`）
- `can_hurt_shooter`：是否可伤害发射者（`bool`）
- 扩展时请在 `_physics_process` 中添加对应逻辑分支

---

## 四、调试与测试规范

### 4.1 运行测试流程
```
1. 主菜单 → Play → 第一关（熊熊小王）
   - 测试：点击有色字射击 → 检查双向删除 → 检查结局
   - 测试：点击无色字 → 检查狐狸嘲讽 → 检查射击次数不消耗

2. 第一关 → 下一关 → 第二关（徐福记）
   - 测试：攻击按钮 → 检查敌人扣血
   - 测试：跳跃按钮 → 检查玩家跳跃动画 → 检查子弹是否穿透
   - 测试：射击按钮 → 检查双向删除 → 检查效果应用
   - 测试：敌人回合 → 检查子弹飞行 → 检查碰撞伤害
```

### 4.2 常见问题排查
| 症状 | 可能原因 | 解决方案 |
|------|----------|----------|
| 句子不显示 | `sentence_updated` 信号未连接 | 检查 `SentenceUI._ready()` 中的信号连接 |
| 点击无反应 | `can_be_shot` 为 `false` | 检查 `WordData` 配置 |
| 子弹不移动 | `BulletScene` 引用为空 | 在场景中拖入 `bullet.tscn` |
| 索引越界 | 敌我句子长度不一致 | 检查 `SentenceConfig` 字数 |
| 下一关按钮不显示 | `next_level_scene` 未设置 | 在场景节点属性中设置 |

### 4.3 日志输出规范
- 使用 `push_error()` 报告严重错误（如资源加载失败）
- 使用 `push_warning()` 报告非致命问题（如未知效果属性）
- 使用 `print()` 报告调试信息（如状态切换、伤害计算）
- 所有日志应包含上下文标识，如 `print("[BattleManager] Player attacked, damage: ", dmg)`

---

## 五、版本管理规范

### 5.1 Git 提交规范
- 格式：`[类型] 简短描述`
- 类型：
  - `feat`：新功能（如 `[feat] 新增第三关防御动作`）
  - `fix`：修复（如 `[fix] 修复第二关句子长度不匹配`）
  - `refactor`：重构（如 `[refactor] 提取公共战斗逻辑到基类`）
  - `docs`：文档（如 `[docs] 更新 CLINE_RULES.md`）
  - `config`：资源配置（如 `[config] 调整第一关敌人属性`）

### 5.2 版本号规则
- `v{major}.{minor}`（如 v0.5）
- `major`：重大架构变更或新增完整关卡
- `minor`：功能调整、Bug 修复、资源配置

---

## 六、Cline 工作流

### 6.1 任务处理流程
```
1. 读取 CLINE_RULES.md 了解项目规范
2. 分析任务需求，确定影响范围（资源/脚本/场景）
3. 检查相关文件当前状态（read_file）
4. 制定修改计划（plan_mode_respond）
5. 执行修改（write_to_file / replace_in_file）
6. 验证修改（检查信号链路、类型安全、边界条件）
7. 更新 task_progress 并提交结果
```

### 6.2 安全操作清单
- [ ] 修改前备份原始文件（或依赖 Git 版本控制）
- [ ] 修改后检查所有信号连接是否完整
- [ ] 确保 `@export` 变量在场景中已正确挂载
- [ ] 测试边界条件（空数组、索引越界、空引用）
- [ ] 验证 `_exit_tree` 中的 Tween 清理

### 6.3 禁止操作
- ❌ 直接修改 `.tscn` 文件内容（场景文件应由 Godot 编辑器管理）
- ❌ 删除未确认不再使用的资源文件
- ❌ 修改 `autoload/global_state.gd` 而不更新文档
- ❌ 在 `_process` 中执行耗时操作（使用 `_physics_process` 替代）

---

## 七、当前任务状态

### ✅ 已完成
- [x] 项目架构搭建（资源类、场景、脚本分离）
- [x] 第一关（熊熊小王）UI 配置与战斗逻辑
- [x] 第二关（徐福记）完整战斗系统
- [x] 主菜单与关卡跳转

### ✅ 已修复的问题（6 次提交）

| # | 问题 | 文件 | 提交信息 |
|---|------|------|----------|
| 1 | "死"字 EffectData 的 attribute="2" 应为 attribute="ending" | `enemy_sentence_lv1.tres` | `[fix] 修复第一关生/死字EffectData配置` |
| 2 | "生"字 EffectData 的 value=2 导致生=失败，与设计相反 | `enemy_sentence_lv1.tres` | 同上 |
| 3 | "死"字 EffectData 缺少 value 字段 | `enemy_sentence_lv1.tres` | 同上 |
| 4 | 第二关 EnemyConfig 缺少 hp、攻击力、子弹方向等属性 | `xu_fuji.tres` | `[config] 修复第二关EnemyConfig和PlayerConfig缺少关键属性` |
| 5 | 第二关 PlayerConfig 缺少 hp、攻击力、跳跃高度等属性 | `player.tres` | 同上 |
| 6 | 第二关 NextLevelBtn 缺少 pressed 信号连接 | `battle_xufuji.tscn` | `[fix] 修复第二关NextLevelBtn缺少信号连接和位置偏移` |
| 7 | 第二关 NextLevelBtn 位置偏移未设置（在左上角） | `battle_xufuji.tscn` | 同上 |
| 8 | 第二关 FoxPopup._on_battle_fox_taunt 方法为空 | `fox_popup.gd` | `[fix] 修复第二关FoxPopup信号处理方法为空` |
| 9 | 第二关 _show_game_over 未设置 NextLevelBtn 可见性 | `battle_manager.gd` | `[fix] 修复第二关_show_game_over未设置NextLevelBtn和RestartBtn可见性` |
| 10 | 第一关缺少 FoxPopup 节点 | `battle_xiongxiong.tscn` | `[fix] 第一关添加FoxPopup节点并连接fox_taunt信号` |

### 📝 未来规划
- [ ] 新增第三关（复制第二关场景 + 修改资源配置）
- [ ] 提取公共战斗逻辑到基类（减少代码重复）
- [ ] 添加音效系统（目前仅主菜单有点击音效）
- [ ] 添加动画系统（角色受伤、射击特效）
- [ ] 完善 `global_state.gd` 全局状态管理

---

## 八、参考资源

- **Godot 4 官方文档**：https://docs.godotengine.org/en/stable/
- **GDScript 风格指南**：https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html
- **信号与回调**：https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html
- **Tween 动画**：https://docs.godotengine.org/en/stable/classes/class_tween.html

---

*最后更新：2026-05-31 | 维护者：Cline (DeepSeek)*

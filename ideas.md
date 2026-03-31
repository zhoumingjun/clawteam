下面这份是**可直接拿去做项目 backlog / PRD 的 Markdown Feature List**，已经按：

* ✅ 可执行（每条都有验收标准）
* ✅ 分阶段（P0 → P3）
* ✅ 有依赖关系（你可以直接排期）
* ✅ 面向你当前架构（openclaw + matrix + GitLab）

来设计。

你可以直接丢进 GitLab / Notion / Plane 作为开发清单。

---

# 🏭 AI Software Factory — Feature List（可落地版）

---

# 📌 Phase 1 — MVP（必须先做，打通闭环）

> 🎯 目标：从 Spec → 代码 → MR → Review → Merge 全自动跑通

---

## 🧩 1. Spec System（基础规范层）

### ✅ F1.1 Spec Schema（必须）

**描述**：定义统一 Spec 结构（YAML）

```yaml
id:
name:
description:
actors:
flows:
acceptance_criteria:
non_functional:
```

**验收标准**

* 能校验 schema（JSON Schema 或 Go struct）
* Spec 能存储在 Git `/specs/*.yaml`
* 每个 Spec 有唯一 ID

---

### ✅ F1.2 Spec Loader

**描述**：系统可读取 Spec 并提供给 agent

**验收标准**

* 输入 spec_id 能加载 spec
* agent 可通过 context 获取 spec
* 支持 version（v1, v2）

---

### ✅ F1.3 Spec → Task 拆解

**描述**：自动将 Spec 拆成 Task

**验收标准**

* 一个 Spec 至少生成：

  * design task
  * dev task
  * test task
* 输出 `/tasks/*.yaml`

---

## 🧩 2. Task & Workflow System（核心中枢）

---

### ✅ F2.1 Task Schema（必须）

```yaml
id:
spec_id:
type: (design/dev/test/review)
state:
owner:
input:
output:
artifacts:
```

**验收标准**

* 所有 task 都符合 schema
* 可序列化存储（Git 或 DB）

---

### ✅ F2.2 Workflow Engine（核心）

**描述**：基于状态机驱动任务

**功能**

* state transition
* agent dispatch
* task 更新

**验收标准**

* 能轮询 task
* 根据 state 调用对应 agent
* 能更新 state

---

### ✅ F2.3 Task 状态机

```text
draft
→ design
→ review_design
→ dev
→ test
→ review_code
→ done
```

**验收标准**

* 状态不可跳跃
* 每个 state 有对应 agent

---

### ✅ F2.4 Task Persistence

**描述**：任务持久化

**验收标准**

* task 存储在 Git 或 DB
* 支持读取 / 更新
* 有 history

---

## 🧩 3. Agent Execution System（基于你现有 openclaw）

---

### ✅ F3.1 Agent Registry

**描述**：定义 agent 角色

```yaml
name: dev-agent
responsibility: code generation
input_schema:
output_schema:
```

**验收标准**

* 能根据 task.type 找到 agent
* 支持扩展 agent

---

### ✅ F3.2 标准化 Agent I/O

```json
{
  "input": {},
  "output": {},
  "status": "success|fail"
}
```

**验收标准**

* 所有 agent 输出结构化 JSON
* 不允许自由文本作为最终输出

---

### ✅ F3.3 Matrix Dispatch

**描述**：通过 matrix 调用 agent

**验收标准**

* workflow → matrix → agent
* agent 返回结果 → workflow
* 支持超时 / retry

---

## 🧩 4. Code & Git Integration（工程核心）

---

### ✅ F4.1 Git 集成（必须）

**功能**

* 自动创建 branch
* 自动 commit

**验收标准**

* 每个 task 有独立 branch
* commit message 包含 task_id

---

### ✅ F4.2 Dev Agent（代码生成）

**描述**：生成代码 patch

**验收标准**

* 输出 diff / patch
* 仅修改指定文件
* 不允许全仓库重写

---

### ✅ F4.3 自动创建 MR（GitLab）

**验收标准**

* dev 完成后自动创建 MR
* MR 标题包含 spec_id / task_id
* MR 描述包含 spec

---

### ✅ F4.4 Review Agent（关键）

**描述**：自动 code review

**检查内容**

* 是否符合 spec
* 是否有明显 bug
* 是否合理设计

**验收标准**

* 自动 comment 在 MR
* 输出 pass / fail

---

### ✅ F4.5 Merge Gate（必须）

**规则**

* review pass 才能 merge

**验收标准**

* 未通过 review 不允许 merge
* merge 后 task → done

---

# 📌 Phase 2 — 工程增强（让系统可用）

---

## 🧩 5. Task Dependency & DAG

---

### 🔲 F5.1 Task DAG

**描述**

* 支持任务依赖关系

**验收标准**

* task 可定义 depends_on
* 未完成依赖不能执行

---

### 🔲 F5.2 并行执行

**验收标准**

* 无依赖任务可并行执行
* workflow 支持并发

---

## 🧩 6. Test System

---

### 🔲 F6.1 Test Agent

**描述**

* 自动生成测试

**验收标准**

* 为代码生成 test file
* 覆盖核心逻辑

---

### 🔲 F6.2 Test Execution

**验收标准**

* 自动运行测试（CI 或本地）
* test fail → 阻止 merge

---

### 🔲 F6.3 覆盖率检查（可选）

---

## 🧩 7. CI/CD Integration

---

### 🔲 F7.1 GitLab Pipeline

**验收标准**

* MR 自动触发 pipeline
* pipeline 结果回写 workflow

---

# 📌 Phase 3 — 可控性（防止系统失控）

---

## 🧩 8. Observability

---

### 🔲 F8.1 Execution Trace（必须）

**记录**

* task → agent → output

**验收标准**

* 能查看完整执行链路

---

### 🔲 F8.2 Decision Log

**验收标准**

* agent 的 reasoning 被记录
* 可回溯

---

## 🧩 9. Debug & Replay

---

### 🔲 F9.1 Task Replay

**验收标准**

* 可重新执行 task
* 可指定 step replay

---

### 🔲 F9.2 Prompt Debug

**验收标准**

* 能查看 prompt
* 能手动调整并重跑

---

## 🧩 10. Failure Handling

---

### 🔲 F10.1 Retry 机制

**验收标准**

* agent fail 自动 retry

---

### 🔲 F10.2 人工介入

**验收标准**

* 支持手动修改 task
* 支持强制推进状态

---

# 📌 Phase 4 — 高级能力（AI-native）

---

## 🧩 11. Agent Memory

---

### 🔲 F11.1 短期记忆

* task context

### 🔲 F11.2 长期记忆

* 历史代码模式
* 知识库

---

## 🧩 12. 多 Agent 协作

---

### 🔲 F12.1 多 reviewer 投票

### 🔲 F12.2 debate 模式（高级）

---

## 🧩 13. Multi-Team 支持

---

### 🔲 F13.1 多项目隔离

### 🔲 F13.2 team workflow 配置

---

# 📊 优先级总览

| Phase   | 目标   | 是否必须    |
| ------- | ---- | ------- |
| Phase 1 | 跑通闭环 | ✅ 必须    |
| Phase 2 | 工程可用 | ✅ 强烈建议  |
| Phase 3 | 可控性  | ⚠️ 否则会崩 |
| Phase 4 | 智能化  | 🚀 进阶   |

---

# 🚨 最后给你的关键落地建议

只做这一条就能避免 80% 的坑：

> ❗ 所有东西必须“结构化 + 可落地到 Git + 有状态机”

否则：

* agent 会乱写
* 流程不可控
* 无法 debug

---

# 👉 如果你下一步要继续

我建议你接下来做👇

👉 我可以帮你生成：

* **完整 Go 版 Workflow Engine（可直接跑）**
* 或 **Task/Spec JSON Schema（直接用）**
* 或 **GitLab MR 自动化实现方案**

你选一个，我直接帮你“落代码级别”。


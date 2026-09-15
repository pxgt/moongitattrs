# MoonGitAttrs

MoonGitAttrs 是一个用 MoonBit 编写的 `.gitattributes` 解析、求值与检查工具。它可以回答“某个文件最终得到哪些属性、由哪一行规则决定”，也能发现常见的配置错误。核心库不访问文件系统，可在 `wasm`、`wasm-gc`、`js` 和 `native` 后端使用；仓库同时提供一个 native CLI。

## 能做什么

- 解析 Set、Unset、Value、Unspecified 四种 Git 属性状态；
- 处理 `*`、`?`、字符组和 `**` 等路径模式；
- 合并根目录、子目录和 `.git/info/attributes` 等多层来源；
- 支持自定义属性宏和 Git 内置的 `binary` 宏；
- 输出规则命中来源、行号和最终属性；
- 检查非法 `eol`、重复赋值、保留属性名和容易误解的宏用法；
- 生成稳定的文本、JSON 和 Markdown 报告。

实现依据是 [Git Attributes 官方文档](https://git-scm.com/docs/gitattributes)。本项目为独立实现，没有复制 Git 的源代码。

## 适用场景

1. 仓库维护者在 CI 中检查 `.gitattributes`，避免行尾、二进制文件或导出规则写错；
2. 开发工具为指定路径展示最终属性和命中规则，定位“为什么 Git 这样处理这个文件”；
3. 代码托管、归档或语言统计工具在不启动 Git 子进程的环境中预先求值属性；
4. 教学和代码审查中演示多层规则的优先级与属性宏展开结果。

## 安装

发布到 Mooncakes 后可添加依赖：

```bash
moon add Xpeng/moongitattrs
```

也可以克隆仓库直接运行：

```bash
git clone https://github.com/pxgt/moongitattrs.git
cd moongitattrs
moon test --target all
moon run cmd/main
```

## 库用法

```moonbit
let rules = @moongitattrs.parse(
  #|[attr]docs text diff
  #|*.md docs eol=lf
  #|assets/** binary
  #|
)

let result = rules.evaluate("README.md")
println(result.to_text())
```

输出会包含最终状态及负责该状态的规则：

```text
path: README.md
attributes:
  diff: set (.gitattributes:2, *.md)
  docs: set (.gitattributes:2, *.md)
  eol: lf (.gitattributes:2, *.md)
  text: set (.gitattributes:2, *.md)
```

按 Git 的低到高优先级组合多个来源：

```moonbit
let rules = @moongitattrs.parse_sources([
  @moongitattrs.AttributeSource::new(".gitattributes", "* text=auto\n"),
  @moongitattrs.AttributeSource::new(
    "docs/.gitattributes",
    "*.md eol=lf\n",
    base_dir="docs",
  ),
  @moongitattrs.AttributeSource::new(
    ".git/info/attributes",
    "README.md export-subst\n",
  ),
])
```

## 命令行用法

仓库内的 [`examples/sample.gitattributes`](examples/sample.gitattributes) 可直接用于复现：

```bash
# 查看某个路径的最终属性
moon run cmd/main -- explain examples/sample.gitattributes README.md

# 输出机器可读 JSON
moon run cmd/main -- explain-json examples/sample.gitattributes README.md

# 检查配置；发现 error 时退出码为 2
moon run cmd/main -- audit examples/sample.gitattributes

# 单独验证一个模式
moon run cmd/main -- match "docs/**" "docs/guide.md"
```

## 审计代码

| 代码 | 含义 |
| --- | --- |
| `MGA001`–`MGA008` | 解析、模式或宏定义诊断 |
| `MGA101` | 同一条规则重复设置同一属性 |
| `MGA102` | 使用 Git 保留的 `builtin_*` 名称 |
| `MGA103`–`MGA104` | `eol` 值或写法可疑 |
| `MGA105` | 以不会展开的状态使用属性宏 |
| `MGA106` | `binary` 与 `text` 在同一规则中冲突 |

## 项目边界

MoonGitAttrs 负责解释配置，不修改工作区，也不执行换行转换、diff/merge 驱动或 GitHub Linguist 分类。库不会自动搜索磁盘上的配置文件；调用方需要按优先级把来源传给 `parse_sources`，CLI 则负责读取单个文件。详细设计见 [`docs/architecture.md`](docs/architecture.md)。

## 开发与验证

```bash
moon fmt --check
moon info --target all
moon check --target all --deny-warn --warn-list +73
moon test --target all --deny-warn --warn-list +73
moon run cmd/main
moon package --frozen
```

完整验证记录和可复现步骤见 [`docs/verification.md`](docs/verification.md)。问题反馈请使用 [GitHub Issues](https://github.com/pxgt/moongitattrs/issues)。安全问题请参阅 [`SECURITY.md`](SECURITY.md)。

## 许可证

Apache-2.0，见 [`LICENSE`](LICENSE)。第三方参考与来源说明见 [`THIRD_PARTY.md`](THIRD_PARTY.md)。

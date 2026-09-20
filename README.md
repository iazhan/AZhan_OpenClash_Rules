# 🚀 AZhan_OpenClash_Rules

AZhan 的 OpenClash 自定义订阅转换配置与分流规则模板。

## ✨ 特性亮点

1. **AI 专属分流与独立分组**：
   - 包含 **Gemini**、**ChatGPT**、**Claude** 及 **海外通用 AI 服务** 独立策略组。
   - 集成 [VPSDance/ai-proxy-rules](https://github.com/VPSDance/ai-proxy-rules) 每日同步更新的高质量规则集。
   - 国内大模型（DeepSeek、Kimi、智谱等）自动走直连，防误翻墙被拒。
2. **专属 GPT 专线自动测速**：
   - 自动匹配包含 `-GPT` 的解锁优质节点，形成 `🤖 GPT专线` 优选组，毫秒级响应。
3. **16 个国家/地区全独立分流**：
   - 包含香港、日本、美国、新加坡、台湾、韩国、英国、加拿大、德国、法国、土耳其、尼日利亚、乌克兰、印度、越南、俄罗斯共 16 个国家/地区独立自动测速节点组。
   - 告别混杂的“其他地区”分组，跨区订阅（如土耳其、尼日利亚低价区）清晰可选。
4. **精细业务分流**：
   - 针对 YouTube、国外流媒体、Telegram 即时通讯、GitHub、谷歌服务、微软、苹果服务提供独立分流。

- `homeproxy/README.md`: **HomeProxy 分流方案完整指南**（基于 DustinWin 二进制规则集，含 LuCI 对照表）
- `homeproxy/setup_homeproxy.sh`: OpenWrt 终端一键 UCI 自动化导入脚本（自动配置规则集与路由）
- `homeproxy/singbox_config_template.json`: sing-box / HomeProxy 自定义配置完整 JSON 模板
- `cfg/openclash_ai.yaml`: **核心原生 OpenClash 完整配置文件**（开箱即用，已剔除无效信息节点并内置 16 国/地区与 AI 分组）
- `scripts/generate_yaml.py`: 自动化 YAML 生成与更新脚本（支持本地文件与订阅链接解析）
- `cfg/raw_subscription.yaml`: 机场原生订阅备份文件（供本地生成脚本使用）
- `cfg/Custom_Clash_AI.ini`: 备用 Subconverter 远程订阅转换模板

## 📖 使用方法

### 方式一：直接在 OpenClash 中导入 YAML（推荐）

1. 在 OpenClash 路由器管理后台，点击 **配置订阅** -> **配置文件管理**；
2. 上传本项目中的 `cfg/openclash_ai.yaml`，或将 GitHub 的 Raw 链接作为订阅地址；
3. 应用并启动 OpenClash 即可。无需依赖任何在线 Subconverter 转换服务，避免隐私泄露、转换超时及格式丢弃问题。

### 方式二：使用 Python 脚本一键生成/刷新 YAML

当机场节点发生变动、新增或密码更新时，可在本机一键重新生成配置：

```bash
# 安装依赖
pip install pyyaml requests

# 方式 2.1：从本地原始订阅备份生成
python scripts/generate_yaml.py

# 方式 2.2：直接通过机场订阅 URL 实时抓取并生成
python scripts/generate_yaml.py --url "你的机场Clash订阅链接"
```

生成的文件将自动保存在 `cfg/openclash_ai.yaml` 中。

---

## 🌐 HomeProxy 分流方案 (基于 DustinWin 规则集)

针对使用 **HomeProxy** (OpenWrt / sing-box) 的软路由用户，本项目提供了基于 [DustinWin/ruleset_geodata](https://github.com/DustinWin/ruleset_geodata) 的高性能二进制规则集方案。

### 快速上手（OpenWrt 终端一键脚本）
在软路由 SSH 终端执行：
```bash
curl -fsSL https://fastly.jsdelivr.net/gh/iazhan/AZhan_OpenClash_Rules@main/homeproxy/setup_homeproxy.sh -o /tmp/setup_homeproxy.sh && sh /tmp/setup_homeproxy.sh
```
- 自动备份现有配置；
- 一键写入 20+ 个 `.srs` 远程二进制规则集（支持 jsDelivr / ghfast 国内加速）；
- 按严格优先级配置 16 项分流路由（国内 AI 直连、Gemini/ChatGPT/Claude 专属分流、流媒体、GFW 等）。

更多细节、sing-box JSON 模板与 LuCI 界面对照表请参阅：[homeproxy/README.md](homeproxy/README.md)。

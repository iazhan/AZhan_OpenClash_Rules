#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
AZhan_OpenClash_Rules - OpenClash 原生 YAML 分流增强配置文件生成器
核心原则：
1. 基础设置（端口、ipv6、allow-lan、experimental、cfw-*、hosts、dns 等）100% 保持原样不动
2. proxies 列表完全保持原样
3. 保留原有全部策略组名称（节点选择、自动选择、ChatGPT、Gemini、Netflix、磁力下载、哔哩哔哩、抖音、Telegram、TikTok、Twitter、WhatsApp、Copilot、微软服务、苹果服务、谷歌服务、Steam）
4. 分流能力增强：
   - 提取 7 个 GPT 优化节点组成「GPT专线」自动测速组，优先接入 ChatGPT、Gemini、Claude、Copilot
   - 新增「Claude」独立策略组
   - 提取 16 个国家/地区独立自动测速组并入「节点选择」
   - 引入 Rule-Providers 规则集，实现国内大模型（DeepSeek、Kimi 等）智能直连与海外 AI（OpenAI、Gemini、Claude 等）精准分流
   - 保留 BT/磁力下载客户端进程级直连拦截
"""

import os
import re
import sys
import argparse
import requests
import yaml

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

REGIONAL_RULES = [
    ("香港节点", r"(🇭🇰|港|\bHK(?:[-_ ]?\d+)?\b|Hong Kong|Hongkong|深港|HKG)"),
    ("日本节点", r"(🇯🇵|日本|川日|东京|大阪|泉日|埼玉|沪日|深日|\bJP(?:[-_ ]?\d+)?\b|Japan|JPN|NRT|HND|KIX|TYO|OSA)"),
    ("新加坡节点", r"(🇸🇬|新加坡|坡|狮城|\bSG(?:[-_ ]?\d+)?\b|Singapore|SIN)"),
    ("美国节点", r"(🇺🇸|美|波特兰|达拉斯|俄勒冈|凤凰城|硅谷|拉斯维加斯|洛杉矶|圣何塞|西雅图|芝加哥|纽约|\bUS(?:[-_ ]?\d+)?\b|United States|USA|America|LAX|SFO|SEA|JFK|EWR)"),
    ("台湾节点", r"(🇹🇼|🇼🇸|台|新北|彰化|\bTW(?:[-_ ]?\d+)?\b|Taiwan|TWN|TPE)"),
    ("韩国节点", r"(🇰🇷|\bKR(?:[-_ ]?\d+)?\b|Korea|KOREA|KOR|首尔|韩|韓|春川|ICN)"),
    ("英国节点", r"(🇬🇧|英|伦敦|London|\bUK(?:[-_ ]?\d+)?\b|Britain|United Kingdom)"),
    ("加拿大节点", r"(🇨🇦|加拿大|温哥华|多伦多|Canada|\bCA(?:[-_ ]?\d+)?\b|(?<!新)加)"),
    ("德国节点", r"(🇩🇪|德国|法兰克福|Germany|\bDE(?:[-_ ]?\d+)?\b)"),
    ("法国节点", r"(🇫🇷|法国|巴黎|France|\bFR(?:[-_ ]?\d+)?\b)"),
    ("土耳其节点", r"(🇹🇷|土耳其|伊斯坦布尔|Turkey|\bTR(?:[-_ ]?\d+)?\b)"),
    ("尼日利亚节点", r"(🇳🇬|尼日利亚|拉各斯|Nigeria|\bNG(?:[-_ ]?\d+)?\b)"),
    ("乌克兰节点", r"(🇺🇦|乌克兰|基辅|Ukraine|\bUA(?:[-_ ]?\d+)?\b)"),
    ("印度节点", r"(🇮🇳|印度|孟买|新德里|India|\bIN(?:[-_ ]?\d+)?\b)"),
    ("越南节点", r"(🇻🇳|越南|胡志明|河内|Vietnam|\bVN(?:[-_ ]?\d+)?\b)"),
    ("俄罗斯节点", r"(🇷🇺|俄罗斯|莫斯科|Russia|\bRU(?:[-_ ]?\d+)?\b)"),
]

INFO_NODE_KEYWORDS = ["剩余流量", "套餐到期", "到期", "过期", "官网", "重置", "有效", "更新时间"]

def is_info_node(name: str) -> bool:
    for kw in INFO_NODE_KEYWORDS:
        if kw in name:
            return True
    return False

def fetch_raw_config(input_path: str = None, url: str = None) -> dict:
    if url:
        print(f"[*] 正在从远程订阅链接拉取配置: {url}")
        headers = {"User-Agent": "ClashMeta/v1.18.0 Mihomo/1.18.0 Clash/1.18.0"}
        resp = requests.get(url, headers=headers, timeout=30)
        resp.raise_for_status()
        content = resp.text
    elif input_path and os.path.exists(input_path):
        print(f"[*] 正在读取本地配置文件: {input_path}")
        with open(input_path, "r", encoding="utf-8") as f:
            content = f.read()
    else:
        raise FileNotFoundError(f"找不到输入源: {input_path or url}")

    data = yaml.safe_load(content)
    if not isinstance(data, dict):
        raise ValueError("订阅内容格式不正确，未能解析为 YAML 字典。")
    return data

def build_enhanced_yaml(raw_config: dict) -> dict:
    # 1. 完全保留原有基础设置
    final_config = {}
    base_fields = [
        "mixed-port", "ipv6", "udp", "allow-lan", "bind-address", "mode", "log-level",
        "unified-delay", "experimental", "cfw-latency-timeout", "cfw-latency-url", "cfw-conn-break-strategy"
    ]
    for key in base_fields:
        if key in raw_config:
            final_config[key] = raw_config[key]

    # 保留 hosts 和 dns
    final_config["hosts"] = raw_config.get("hosts", {})
    final_config["dns"] = raw_config.get("dns", {})

    # 保留 proxies
    raw_proxies = raw_config.get("proxies", [])
    final_config["proxies"] = raw_proxies

    # 提取真实代理节点名称（剔除流量/到期节点以构建测速组）
    real_proxy_names = [p["name"] for p in raw_proxies if not is_info_node(p.get("name", ""))]
    all_raw_names = [p["name"] for p in raw_proxies]

    # 2. 节点分类
    region_map = {}
    for group_name, pattern in REGIONAL_RULES:
        matched = [n for n in real_proxy_names if re.search(pattern, n, re.IGNORECASE)]
        region_map[group_name] = matched
        print(f"    - {group_name}: {len(matched)} 个节点")

    # 3. 提取 7 个 GPT 专线节点
    gpt_nodes = [n for n in real_proxy_names if re.search(r"gpt", n, re.IGNORECASE)]
    print(f"    - GPT专线: {len(gpt_nodes)} 个节点")

    # 4. 构建策略组（保留原有全部名称，并进行分流增强）
    all_region_group_names = [g[0] for g in REGIONAL_RULES if region_map.get(g[0])]

    proxy_groups = [
        # [核心总控]
        {
            "name": "节点选择",
            "type": "select",
            "proxies": ["自动选择", "GPT专线"] + all_region_group_names + all_raw_names
        },
        # [自动选择：对真实节点自动测速]
        {
            "name": "自动选择",
            "type": "url-test",
            "url": raw_config.get("cfw-latency-url", "http://YouTube.com/generate_204"),
            "interval": 300,
            "tolerance": 50,
            "proxies": list(real_proxy_names)
        },
        # [GPT专线：专为 7 个 GPT 解锁节点自动测速]
        {
            "name": "GPT专线",
            "type": "url-test",
            "url": raw_config.get("cfw-latency-url", "http://YouTube.com/generate_204"),
            "interval": 300,
            "tolerance": 50,
            "proxies": list(gpt_nodes) if gpt_nodes else list(real_proxy_names)
        },
        # [ChatGPT：优先走 GPT 专线与美/新/日/台/英优质节点]
        {
            "name": "ChatGPT",
            "type": "select",
            "proxies": ["GPT专线", "节点选择"] + gpt_nodes + ["美国节点", "新加坡节点", "日本节点", "台湾节点", "英国节点"]
        },
        # [Gemini：优先走 谷歌服务 / GPT 专线与美/新/日/台优质节点，避开香港]
        {
            "name": "Gemini",
            "type": "select",
            "proxies": ["谷歌服务", "GPT专线", "节点选择", "美国节点", "新加坡节点", "日本节点", "台湾节点", "英国节点"]
        },
        # [Claude：新增 Claude 独立策略组]
        {
            "name": "Claude",
            "type": "select",
            "proxies": ["GPT专线", "节点选择", "美国节点", "新加坡节点", "日本节点", "台湾节点", "英国节点"]
        },
        # [Copilot]
        {
            "name": "Copilot",
            "type": "select",
            "proxies": ["节点选择", "DIRECT", "GPT专线", "美国节点", "新加坡节点", "日本节点"] + all_raw_names
        },
        # [Netflix]
        {
            "name": "Netflix",
            "type": "select",
            "proxies": ["节点选择", "自动选择", "新加坡节点", "日本节点", "美国节点", "台湾节点", "香港节点", "英国节点", "土耳其节点", "尼日利亚节点"] + all_raw_names
        },
        # [磁力下载：强制走 DIRECT 防封]
        {
            "name": "磁力下载",
            "type": "select",
            "proxies": ["DIRECT"]
        },
        # [哔哩哔哩]
        {
            "name": "哔哩哔哩",
            "type": "select",
            "proxies": ["DIRECT", "节点选择", "香港节点", "台湾节点", "日本节点"] + all_raw_names
        },
        # [抖音]
        {
            "name": "抖音",
            "type": "select",
            "proxies": ["DIRECT", "节点选择"] + all_raw_names
        },
        # [Telegram]
        {
            "name": "Telegram",
            "type": "select",
            "proxies": ["节点选择", "自动选择", "香港节点", "新加坡节点", "日本节点", "美国节点", "台湾节点"]
        },
        # [TikTok]
        {
            "name": "TikTok",
            "type": "select",
            "proxies": ["日本节点", "新加坡节点", "美国节点", "韩国节点", "法国节点", "越南节点", "俄罗斯节点", "土耳其节点", "尼日利亚节点", "节点选择"]
        },
        # [Twitter]
        {
            "name": "Twitter",
            "type": "select",
            "proxies": ["节点选择", "自动选择", "香港节点", "新加坡节点", "日本节点", "美国节点", "台湾节点"]
        },
        # [WhatsApp]
        {
            "name": "WhatsApp",
            "type": "select",
            "proxies": ["节点选择", "自动选择", "香港节点", "新加坡节点", "日本节点", "美国节点", "台湾节点"]
        },
        # [微软服务]
        {
            "name": "微软服务",
            "type": "select",
            "proxies": ["DIRECT", "节点选择", "香港节点", "美国节点", "新加坡节点", "日本节点"] + all_raw_names
        },
        # [苹果服务]
        {
            "name": "苹果服务",
            "type": "select",
            "proxies": ["DIRECT", "节点选择", "香港节点", "美国节点", "新加坡节点", "日本节点"] + all_raw_names
        },
        # [谷歌服务]
        {
            "name": "谷歌服务",
            "type": "select",
            "proxies": ["节点选择", "自动选择", "新加坡节点", "日本节点", "美国节点", "台湾节点", "香港节点"] + all_raw_names
        },
        # [Steam]
        {
            "name": "Steam",
            "type": "select",
            "proxies": ["节点选择", "DIRECT", "香港节点", "日本节点", "新加坡节点", "美国节点"] + all_raw_names
        },
        # [漏网之鱼：兜底分流]
        {
            "name": "漏网之鱼",
            "type": "select",
            "proxies": ["节点选择", "自动选择", "DIRECT"]
        }
    ]

    # 添加 16 个国家/地区独立自动测速组
    for group_name, _ in REGIONAL_RULES:
        nodes = region_map.get(group_name, [])
        if nodes:
            proxy_groups.append({
                "name": group_name,
                "type": "url-test",
                "url": raw_config.get("cfw-latency-url", "http://YouTube.com/generate_204"),
                "interval": 300,
                "tolerance": 50,
                "proxies": list(nodes)
            })

    final_config["proxy-groups"] = proxy_groups

    # 5. 构建 Rule-Providers 规则集（每日自动更新）
    # 使用 Loyalsoldier/clash-rules + VPSDance/ai-proxy-rules 远程规则集
    # 完全不依赖本地 geosite.dat，避免版本兼容性问题
    rule_provider_base = "https://cdn.jsdelivr.net/gh"
    loyalsoldier = f"{rule_provider_base}/Loyalsoldier/clash-rules@release"
    vpsdance = f"{rule_provider_base}/VPSDance/ai-proxy-rules@main/rules/clash"

    final_config["rule-providers"] = {
        # === AI 相关 ===
        "ai-cn": {
            "type": "http",
            "behavior": "classical",
            "url": f"{vpsdance}/cn.yaml",
            "path": "./ruleset/ai-cn.yaml",
            "interval": 86400
        },
        "google-ai": {
            "type": "http",
            "behavior": "classical",
            "url": f"{vpsdance}/google-ai.yaml",
            "path": "./ruleset/google-ai.yaml",
            "interval": 86400
        },
        "openai": {
            "type": "http",
            "behavior": "classical",
            "url": f"{vpsdance}/openai.yaml",
            "path": "./ruleset/openai.yaml",
            "interval": 86400
        },
        "anthropic": {
            "type": "http",
            "behavior": "classical",
            "url": f"{vpsdance}/anthropic.yaml",
            "path": "./ruleset/anthropic.yaml",
            "interval": 86400
        },
        "ai-global": {
            "type": "http",
            "behavior": "classical",
            "url": f"{vpsdance}/global.yaml",
            "path": "./ruleset/ai-global.yaml",
            "interval": 86400
        },
        # === 流媒体与社交 ===
        "tiktok": {
            "type": "http",
            "behavior": "classical",
            "url": f"{rule_provider_base}/blackmatrix7/ios_rule_script@master/rule/Clash/TikTok/TikTok.yaml",
            "path": "./ruleset/tiktok.yaml",
            "interval": 86400
        },
        "netflix": {
            "type": "http",
            "behavior": "classical",
            "url": f"{rule_provider_base}/blackmatrix7/ios_rule_script@master/rule/Clash/Netflix/Netflix.yaml",
            "path": "./ruleset/netflix.yaml",
            "interval": 86400
        },
        "bilibili": {
            "type": "http",
            "behavior": "classical",
            "url": f"{rule_provider_base}/blackmatrix7/ios_rule_script@master/rule/Clash/BiliBili/BiliBili.yaml",
            "path": "./ruleset/bilibili.yaml",
            "interval": 86400
        },
        "telegram": {
            "type": "http",
            "behavior": "classical",
            "url": f"{rule_provider_base}/blackmatrix7/ios_rule_script@master/rule/Clash/Telegram/Telegram.yaml",
            "path": "./ruleset/telegram.yaml",
            "interval": 86400
        },
        "twitter": {
            "type": "http",
            "behavior": "classical",
            "url": f"{rule_provider_base}/blackmatrix7/ios_rule_script@master/rule/Clash/Twitter/Twitter.yaml",
            "path": "./ruleset/twitter.yaml",
            "interval": 86400
        },
        "whatsapp": {
            "type": "http",
            "behavior": "classical",
            "url": f"{rule_provider_base}/blackmatrix7/ios_rule_script@master/rule/Clash/Whatsapp/Whatsapp.yaml",
            "path": "./ruleset/whatsapp.yaml",
            "interval": 86400
        },
        "douyin": {
            "type": "http",
            "behavior": "classical",
            "url": f"{rule_provider_base}/blackmatrix7/ios_rule_script@master/rule/Clash/DouYin/DouYin.yaml",
            "path": "./ruleset/douyin.yaml",
            "interval": 86400
        },
        # === 服务商 ===
        "steam": {
            "type": "http",
            "behavior": "classical",
            "url": f"{rule_provider_base}/blackmatrix7/ios_rule_script@master/rule/Clash/Steam/Steam.yaml",
            "path": "./ruleset/steam.yaml",
            "interval": 86400
        },
        "microsoft": {
            "type": "http",
            "behavior": "classical",
            "url": f"{rule_provider_base}/blackmatrix7/ios_rule_script@master/rule/Clash/Microsoft/Microsoft.yaml",
            "path": "./ruleset/microsoft.yaml",
            "interval": 86400
        },
        "apple": {
            "type": "http",
            "behavior": "classical",
            "url": f"{rule_provider_base}/blackmatrix7/ios_rule_script@master/rule/Clash/Apple/Apple.yaml",
            "path": "./ruleset/apple.yaml",
            "interval": 86400
        },
        "google": {
            "type": "http",
            "behavior": "classical",
            "url": f"{rule_provider_base}/blackmatrix7/ios_rule_script@master/rule/Clash/Google/Google.yaml",
            "path": "./ruleset/google.yaml",
            "interval": 86400
        },
        # === 基础分流 ===
        "gfw": {
            "type": "http",
            "behavior": "domain",
            "url": f"{loyalsoldier}/gfw.txt",
            "path": "./ruleset/gfw.yaml",
            "interval": 86400
        },
        "direct-domains": {
            "type": "http",
            "behavior": "domain",
            "url": f"{loyalsoldier}/direct.txt",
            "path": "./ruleset/direct-domains.yaml",
            "interval": 86400
        },
    }

    # 6. 精炼高效分流规则（完全使用 Rule-Provider + GEOIP，不依赖 GEOSITE）
    final_config["rules"] = [
        # [机场自用与保障直连]
        "DOMAIN,api.mojie.ws,DIRECT",
        "DOMAIN-KEYWORD,mojie,自动选择",
        "DOMAIN-SUFFIX,zoot.plus,DIRECT",
        "DOMAIN-SUFFIX,prts.plus,DIRECT",

        # [局域网与私有地址直连]
        "GEOIP,lan,DIRECT,no-resolve",
        "IP-CIDR,127.0.0.0/8,DIRECT,no-resolve",
        "IP-CIDR,172.16.0.0/12,DIRECT,no-resolve",
        "IP-CIDR,192.168.0.0/16,DIRECT,no-resolve",
        "IP-CIDR,10.0.0.0/8,DIRECT,no-resolve",
        "IP-CIDR,100.64.0.0/10,DIRECT,no-resolve",
        "IP-CIDR6,fe80::/10,DIRECT,no-resolve",

        # [BT / 磁力下载客户端直连防封]
        "PROCESS-NAME,Thunder,磁力下载",
        "PROCESS-NAME,DownloadService,磁力下载",
        "PROCESS-NAME,qBittorrent,磁力下载",
        "PROCESS-NAME,Transmission,磁力下载",
        "PROCESS-NAME,fdm,磁力下载",
        "PROCESS-NAME,aria2c,磁力下载",
        "PROCESS-NAME,Folx,磁力下载",
        "PROCESS-NAME,NetTransport,磁力下载",
        "PROCESS-NAME,uTorrent,磁力下载",
        "PROCESS-NAME,WebTorrent,磁力下载",
        "PROCESS-NAME,aria2c.exe,磁力下载",
        "PROCESS-NAME,BitComet.exe,磁力下载",
        "PROCESS-NAME,fdm.exe,磁力下载",
        "PROCESS-NAME,NetTransport.exe,磁力下载",
        "PROCESS-NAME,qbittorrent.exe,磁力下载",
        "PROCESS-NAME,Thunder.exe,磁力下载",
        "PROCESS-NAME,ThunderVIP.exe,磁力下载",
        "PROCESS-NAME,transmission-daemon.exe,磁力下载",
        "PROCESS-NAME,transmission-qt.exe,磁力下载",
        "PROCESS-NAME,uTorrent.exe,磁力下载",
        "PROCESS-NAME,WebTorrent.exe,磁力下载",
        "DOMAIN-KEYWORD,tracker,磁力下载",

        # [国内 AI 大模型智能直连 (DeepSeek、Kimi、通义千问、智谱等)]
        "RULE-SET,ai-cn,DIRECT",

        # [海外 AI 强化专属分流]
        "RULE-SET,google-ai,Gemini",
        "RULE-SET,openai,ChatGPT",
        "RULE-SET,anthropic,Claude",
        "RULE-SET,ai-global,ChatGPT",

        # [Copilot 显式域名分流]
        "DOMAIN-SUFFIX,copilot.microsoft.com,Copilot",
        "DOMAIN,copilot.cloud.microsoft,Copilot",
        "DOMAIN-SUFFIX,sydney.bing.com,Copilot",
        "DOMAIN,www.bing.com,Copilot",
        "DOMAIN,r.bing.com,Copilot",
        "DOMAIN,edgeservices.bing.com,Copilot",
        "DOMAIN-SUFFIX,bing.net,Copilot",
        "DOMAIN,api.githubcopilot.com,Copilot",
        "DOMAIN,copilot-proxy.githubusercontent.com,Copilot",
        "DOMAIN-KEYWORD,copilot,Copilot",

        # [业务精细分流：使用 Rule-Provider 远程规则集]
        "RULE-SET,tiktok,TikTok",
        "RULE-SET,twitter,Twitter",
        "RULE-SET,telegram,Telegram",
        "GEOIP,telegram,Telegram,no-resolve",
        "RULE-SET,whatsapp,WhatsApp",
        "RULE-SET,bilibili,哔哩哔哩",
        "RULE-SET,douyin,抖音",
        "RULE-SET,netflix,Netflix",
        "RULE-SET,steam,Steam",
        "RULE-SET,microsoft,微软服务",
        "RULE-SET,apple,苹果服务",
        "RULE-SET,google,谷歌服务",
        "GEOIP,google,谷歌服务,no-resolve",

        # [兜底与国内直连]
        "RULE-SET,gfw,节点选择",
        "RULE-SET,direct-domains,DIRECT",
        "GEOIP,cn,DIRECT,no-resolve",
        "MATCH,漏网之鱼"
    ]

    return final_config

def main():
    parser = argparse.ArgumentParser(description="生成强化版 OpenClash YAML 配置文件")
    parser.add_argument("--input", "-i", default="cfg/raw_subscription.yaml", help="本地原始订阅 YAML 文件路径")
    parser.add_argument("--url", "-u", default=None, help="远程订阅下载链接")
    parser.add_argument("--output", "-o", default="cfg/openclash_ai.yaml", help="生成的目标 OpenClash YAML 文件路径")
    args = parser.parse_args()

    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    input_file = os.path.join(project_root, args.input) if not os.path.isabs(args.input) else args.input
    output_file = os.path.join(project_root, args.output) if not os.path.isabs(args.output) else args.output

    print("==================================================")
    print("🚀 AZhan_OpenClash_Rules - OpenClash YAML 增强生成器")
    print("==================================================")

    raw_config = fetch_raw_config(input_path=input_file, url=args.url)
    openclash_yaml = build_enhanced_yaml(raw_config)

    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    with open(output_file, "w", encoding="utf-8") as f:
        yaml.dump(openclash_yaml, f, allow_unicode=True, sort_keys=False, default_flow_style=False)

    print(f"\n[✔] 成功生成增强版 OpenClash 配置文件: {output_file}")
    print("==================================================")

if __name__ == "__main__":
    main()

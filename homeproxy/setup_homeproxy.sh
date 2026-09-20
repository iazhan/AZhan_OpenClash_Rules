#!/bin/sh
# ==============================================================================
# HomeProxy 一键分流规则集与路由规则配置脚本 (基于 DustinWin/ruleset_geodata)
# 适用于：OpenWrt / ImmortalWrt 搭载的 luci-app-homeproxy (sing-box)
# ==============================================================================

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}======================================================${NC}"
echo -e "${GREEN}🚀 HomeProxy 分流规则集一键配置工具${NC}"
echo -e "${GREEN}基于 DustinWin/ruleset_geodata 二进制规则集 (.srs)${NC}"
echo -e "${BLUE}======================================================${NC}"

# 检查环境
if [ ! -f "/etc/config/homeproxy" ]; then
    echo -e "${RED}[ERROR] 未检测到 /etc/config/homeproxy，请确认已安装 HomeProxy 插件！${NC}"
    exit 1
fi

# 选择下载 CDN 源
echo -e "\n${YELLOW}请选择规则集下载源（软路由访问 GitHub 建议选择 1 或 2）：${NC}"
echo "1) jsDelivr CDN 加速 (默认推荐: cdn.jsdelivr.net)"
echo "2) ghfast.top 镜像加速 (ghfast.top)"
echo "3) GitHub 官方源 (需要软路由环境可直连 GitHub)"
read -p "请输入选项 [1-3] (默认为 1): " CDN_CHOICE

case "$CDN_CHOICE" in
    2)
        BASE_URL="https://ghfast.top/https://github.com/DustinWin/ruleset_geodata/releases/download/sing-box-ruleset"
        echo -e "[*] 已选择：ghfast.top 镜像加速"
        ;;
    3)
        BASE_URL="https://github.com/DustinWin/ruleset_geodata/releases/download/sing-box-ruleset"
        echo -e "[*] 已选择：GitHub 官方 Releases"
        ;;
    *)
        BASE_URL="https://cdn.jsdelivr.net/gh/DustinWin/ruleset_geodata@sing-box-ruleset"
        echo -e "[*] 已选择：jsDelivr CDN 加速"
        ;;
esac

# 备份现有配置
BACKUP_FILE="/etc/config/homeproxy.bak.$(date +%Y%m%d_%H%M%S)"
cp /etc/config/homeproxy "$BACKUP_FILE"
echo -e "[*] 已备份现有配置至: ${YELLOW}${BACKUP_FILE}${NC}"

echo -e "\n[*] 正在向 /etc/config/homeproxy 写入规则集 (Rule-sets)..."

# 批量添加规则集
uci batch <<EOF
# 1. 基础与安全
set homeproxy.rs_ads=ruleset
set homeproxy.rs_ads.label='🛑 广告拦截'
set homeproxy.rs_ads.enabled='1'
set homeproxy.rs_ads.type='remote'
set homeproxy.rs_ads.format='binary'
set homeproxy.rs_ads.url='${BASE_URL}/ads.srs'

set homeproxy.rs_private=ruleset
set homeproxy.rs_private.label='🔒 私有域名'
set homeproxy.rs_private.enabled='1'
set homeproxy.rs_private.type='remote'
set homeproxy.rs_private.format='binary'
set homeproxy.rs_private.url='${BASE_URL}/private.srs'

set homeproxy.rs_privateip=ruleset
set homeproxy.rs_privateip.label='🔒 私有IP'
set homeproxy.rs_privateip.enabled='1'
set homeproxy.rs_privateip.type='remote'
set homeproxy.rs_privateip.format='binary'
set homeproxy.rs_privateip.url='${BASE_URL}/privateip.srs'

# 2. 直连下载与 Trackers
set homeproxy.rs_applications=ruleset
set homeproxy.rs_applications.label='⬇️ 直连软件'
set homeproxy.rs_applications.enabled='1'
set homeproxy.rs_applications.type='remote'
set homeproxy.rs_applications.format='binary'
set homeproxy.rs_applications.url='${BASE_URL}/applications.srs'

set homeproxy.rs_trackers=ruleset
set homeproxy.rs_trackers.label='📋 BT Trackers'
set homeproxy.rs_trackers.enabled='1'
set homeproxy.rs_trackers.type='remote'
set homeproxy.rs_trackers.format='binary'
set homeproxy.rs_trackers.url='${BASE_URL}/trackerslist.srs'

# 3. 海外 AI
set homeproxy.rs_ai=ruleset
set homeproxy.rs_ai.label='🤖 AI 平台'
set homeproxy.rs_ai.enabled='1'
set homeproxy.rs_ai.type='remote'
set homeproxy.rs_ai.format='binary'
set homeproxy.rs_ai.url='${BASE_URL}/ai.srs'

# 4. 流媒体
set homeproxy.rs_youtube=ruleset
set homeproxy.rs_youtube.label='📹 油管视频'
set homeproxy.rs_youtube.enabled='1'
set homeproxy.rs_youtube.type='remote'
set homeproxy.rs_youtube.format='binary'
set homeproxy.rs_youtube.url='${BASE_URL}/youtube.srs'

set homeproxy.rs_netflix=ruleset
set homeproxy.rs_netflix.label='🎥 奈飞视频'
set homeproxy.rs_netflix.enabled='1'
set homeproxy.rs_netflix.type='remote'
set homeproxy.rs_netflix.format='binary'
set homeproxy.rs_netflix.url='${BASE_URL}/netflix.srs'

set homeproxy.rs_netflixip=ruleset
set homeproxy.rs_netflixip.label='🎥 奈飞IP'
set homeproxy.rs_netflixip.enabled='1'
set homeproxy.rs_netflixip.type='remote'
set homeproxy.rs_netflixip.format='binary'
set homeproxy.rs_netflixip.url='${BASE_URL}/netflixip.srs'

set homeproxy.rs_disney=ruleset
set homeproxy.rs_disney.label='📽️ 迪士尼+'
set homeproxy.rs_disney.enabled='1'
set homeproxy.rs_disney.type='remote'
set homeproxy.rs_disney.format='binary'
set homeproxy.rs_disney.url='${BASE_URL}/disney.srs'

set homeproxy.rs_max=ruleset
set homeproxy.rs_max.label='🎞️ Max'
set homeproxy.rs_max.enabled='1'
set homeproxy.rs_max.type='remote'
set homeproxy.rs_max.format='binary'
set homeproxy.rs_max.url='${BASE_URL}/max.srs'

set homeproxy.rs_primevideo=ruleset
set homeproxy.rs_primevideo.label='🎬 Prime Video'
set homeproxy.rs_primevideo.enabled='1'
set homeproxy.rs_primevideo.type='remote'
set homeproxy.rs_primevideo.format='binary'
set homeproxy.rs_primevideo.url='${BASE_URL}/primevideo.srs'

set homeproxy.rs_appletv=ruleset
set homeproxy.rs_appletv.label='🍎 Apple TV+'
set homeproxy.rs_appletv.enabled='1'
set homeproxy.rs_appletv.type='remote'
set homeproxy.rs_appletv.format='binary'
set homeproxy.rs_appletv.url='${BASE_URL}/appletv.srs'

set homeproxy.rs_spotify=ruleset
set homeproxy.rs_spotify.label='🎶 Spotify'
set homeproxy.rs_spotify.enabled='1'
set homeproxy.rs_spotify.type='remote'
set homeproxy.rs_spotify.format='binary'
set homeproxy.rs_spotify.url='${BASE_URL}/spotify.srs'

set homeproxy.rs_media=ruleset
set homeproxy.rs_media.label='🌍 国外媒体'
set homeproxy.rs_media.enabled='1'
set homeproxy.rs_media.type='remote'
set homeproxy.rs_media.format='binary'
set homeproxy.rs_media.url='${BASE_URL}/media.srs'

set homeproxy.rs_mediaip=ruleset
set homeproxy.rs_mediaip.label='🌍 国外媒体IP'
set homeproxy.rs_mediaip.enabled='1'
set homeproxy.rs_mediaip.type='remote'
set homeproxy.rs_mediaip.format='binary'
set homeproxy.rs_mediaip.url='${BASE_URL}/mediaip.srs'

# 5. 社交与通讯
set homeproxy.rs_tiktok=ruleset
set homeproxy.rs_tiktok.label='🎵 TikTok'
set homeproxy.rs_tiktok.enabled='1'
set homeproxy.rs_tiktok.type='remote'
set homeproxy.rs_tiktok.format='binary'
set homeproxy.rs_tiktok.url='${BASE_URL}/tiktok.srs'

set homeproxy.rs_telegramip=ruleset
set homeproxy.rs_telegramip.label='📲 电报IP'
set homeproxy.rs_telegramip.enabled='1'
set homeproxy.rs_telegramip.type='remote'
set homeproxy.rs_telegramip.format='binary'
set homeproxy.rs_telegramip.url='${BASE_URL}/telegramip.srs'

# 6. 国内服务
set homeproxy.rs_googlecn=ruleset
set homeproxy.rs_googlecn.label='🇬 谷歌国内服务'
set homeproxy.rs_googlecn.enabled='1'
set homeproxy.rs_googlecn.type='remote'
set homeproxy.rs_googlecn.format='binary'
set homeproxy.rs_googlecn.url='${BASE_URL}/google-cn.srs'

set homeproxy.rs_applecn=ruleset
set homeproxy.rs_applecn.label='🍎 苹果国内服务'
set homeproxy.rs_applecn.enabled='1'
set homeproxy.rs_applecn.type='remote'
set homeproxy.rs_applecn.format='binary'
set homeproxy.rs_applecn.url='${BASE_URL}/apple-cn.srs'

set homeproxy.rs_mscn=ruleset
set homeproxy.rs_mscn.label='🪟 微软国内服务'
set homeproxy.rs_mscn.enabled='1'
set homeproxy.rs_mscn.type='remote'
set homeproxy.rs_mscn.format='binary'
set homeproxy.rs_mscn.url='${BASE_URL}/microsoft-cn.srs'

set homeproxy.rs_gamescn=ruleset
set homeproxy.rs_gamescn.label='🎮 游戏国内服务'
set homeproxy.rs_gamescn.enabled='1'
set homeproxy.rs_gamescn.type='remote'
set homeproxy.rs_gamescn.format='binary'
set homeproxy.rs_gamescn.url='${BASE_URL}/games-cn.srs'

set homeproxy.rs_bilibili=ruleset
set homeproxy.rs_bilibili.label='📺 哔哩哔哩'
set homeproxy.rs_bilibili.enabled='1'
set homeproxy.rs_bilibili.type='remote'
set homeproxy.rs_bilibili.format='binary'
set homeproxy.rs_bilibili.url='${BASE_URL}/bilibili.srs'

# 7. 游戏与工具
set homeproxy.rs_games=ruleset
set homeproxy.rs_games.label='🕹️ 游戏平台'
set homeproxy.rs_games.enabled='1'
set homeproxy.rs_games.type='remote'
set homeproxy.rs_games.format='binary'
set homeproxy.rs_games.url='${BASE_URL}/games.srs'

set homeproxy.rs_networktest=ruleset
set homeproxy.rs_networktest.label='📈 网络测试'
set homeproxy.rs_networktest.enabled='1'
set homeproxy.rs_networktest.type='remote'
set homeproxy.rs_networktest.format='binary'
set homeproxy.rs_networktest.url='${BASE_URL}/networktest.srs'

# 8. 代理与直连兜底
set homeproxy.rs_gfw=ruleset
set homeproxy.rs_gfw.label='🌎 GFW 域名'
set homeproxy.rs_gfw.enabled='1'
set homeproxy.rs_gfw.type='remote'
set homeproxy.rs_gfw.format='binary'
set homeproxy.rs_gfw.url='${BASE_URL}/gfw.srs'

set homeproxy.rs_proxy=ruleset
set homeproxy.rs_proxy.label='🌎 国外域名'
set homeproxy.rs_proxy.enabled='1'
set homeproxy.rs_proxy.type='remote'
set homeproxy.rs_proxy.format='binary'
set homeproxy.rs_proxy.url='${BASE_URL}/proxy.srs'

set homeproxy.rs_tldproxy=ruleset
set homeproxy.rs_tldproxy.label='🌎 国外顶级域名'
set homeproxy.rs_tldproxy.enabled='1'
set homeproxy.rs_tldproxy.type='remote'
set homeproxy.rs_tldproxy.format='binary'
set homeproxy.rs_tldproxy.url='${BASE_URL}/tld-proxy.srs'

set homeproxy.rs_cn=ruleset
set homeproxy.rs_cn.label='🇨🇳 国内域名'
set homeproxy.rs_cn.enabled='1'
set homeproxy.rs_cn.type='remote'
set homeproxy.rs_cn.format='binary'
set homeproxy.rs_cn.url='${BASE_URL}/cn.srs'

set homeproxy.rs_cnip=ruleset
set homeproxy.rs_cnip.label='🀄️ 国内 IP'
set homeproxy.rs_cnip.enabled='1'
set homeproxy.rs_cnip.type='remote'
set homeproxy.rs_cnip.format='binary'
set homeproxy.rs_cnip.url='${BASE_URL}/cnip.srs'
EOF

echo -e "[*] 正在向 /etc/config/homeproxy 写入策略组 (Routing Nodes)..."

# 批量添加策略组（出站分组）
uci batch <<EOF
set homeproxy.rn_gemini=routing_node
set homeproxy.rn_gemini.label='🤖 Google Gemini'
set homeproxy.rn_gemini.enabled='1'
set homeproxy.rn_gemini.node='default-node'

set homeproxy.rn_chatgpt=routing_node
set homeproxy.rn_chatgpt.label='🤖 OpenAI ChatGPT'
set homeproxy.rn_chatgpt.enabled='1'
set homeproxy.rn_chatgpt.node='default-node'

set homeproxy.rn_claude=routing_node
set homeproxy.rn_claude.label='🤖 Anthropic Claude'
set homeproxy.rn_claude.enabled='1'
set homeproxy.rn_claude.node='default-node'

set homeproxy.rn_ai=routing_node
set homeproxy.rn_ai.label='🤖 海外通用 AI'
set homeproxy.rn_ai.enabled='1'
set homeproxy.rn_ai.node='default-node'

set homeproxy.rn_media=routing_node
set homeproxy.rn_media.label='🎥 国外媒体与视频'
set homeproxy.rn_media.enabled='1'
set homeproxy.rn_media.node='default-node'

set homeproxy.rn_social=routing_node
set homeproxy.rn_social.label='💬 即时通讯与社交'
set homeproxy.rn_social.enabled='1'
set homeproxy.rn_social.node='default-node'

set homeproxy.rn_github=routing_node
set homeproxy.rn_github.label='🚀 GitHub'
set homeproxy.rn_github.enabled='1'
set homeproxy.rn_github.node='default-node'

set homeproxy.rn_games=routing_node
set homeproxy.rn_games.label='🕹️ 游戏平台'
set homeproxy.rn_games.enabled='1'
set homeproxy.rn_games.node='default-node'
EOF

echo -e "[*] 正在向 /etc/config/homeproxy 写入分流路由规则 (Routing Rules)..."

# 批量添加分流路由规则（优先级自上而下）
uci batch <<EOF
# 1. 局域网与私有网络直连
set homeproxy.rr_private=routing_rule
set homeproxy.rr_private.label='1. 私网与局域网直连'
set homeproxy.rr_private.enabled='1'
set homeproxy.rr_private.mode='default'
add_list homeproxy.rr_private.rule_set='rs_private'
add_list homeproxy.rr_private.rule_set='rs_privateip'
set homeproxy.rr_private.outbound='direct'

# 2. 广告拦截
set homeproxy.rr_ads=routing_rule
set homeproxy.rr_ads.label='2. 广告与隐私拦截'
set homeproxy.rr_ads.enabled='1'
set homeproxy.rr_ads.mode='default'
add_list homeproxy.rr_ads.rule_set='rs_ads'
set homeproxy.rr_ads.outbound='reject'

# 3. BT / 下载工具直连
set homeproxy.rr_bt=routing_rule
set homeproxy.rr_bt.label='3. BT与下载直连'
set homeproxy.rr_bt.enabled='1'
set homeproxy.rr_bt.mode='default'
add_list homeproxy.rr_bt.rule_set='rs_applications'
add_list homeproxy.rr_bt.rule_set='rs_trackers'
set homeproxy.rr_bt.outbound='direct'

# 4. 国内大模型直连 (DeepSeek, Kimi, 智谱等)
set homeproxy.rr_cn_ai=routing_rule
set homeproxy.rr_cn_ai.label='4. 国内大模型直连'
set homeproxy.rr_cn_ai.enabled='1'
set homeproxy.rr_cn_ai.mode='default'
add_list homeproxy.rr_cn_ai.domain_suffix='deepseek.com'
add_list homeproxy.rr_cn_ai.domain_suffix='moonshot.cn'
add_list homeproxy.rr_cn_ai.domain_suffix='kimi.ai'
add_list homeproxy.rr_cn_ai.domain_suffix='baichuan-ai.com'
add_list homeproxy.rr_cn_ai.domain_suffix='zhipuai.cn'
add_list homeproxy.rr_cn_ai.domain_suffix='chatglm.cn'
add_list homeproxy.rr_cn_ai.domain_suffix='minimax.chat'
add_list homeproxy.rr_cn_ai.domain_suffix='stepfun.com'
add_list homeproxy.rr_cn_ai.domain_suffix='doubao.com'
add_list homeproxy.rr_cn_ai.domain_suffix='aliyun.com'
add_list homeproxy.rr_cn_ai.domain_suffix='qwen.ai'
set homeproxy.rr_cn_ai.outbound='direct'

# 5. Gemini 专属代理
set homeproxy.rr_gemini=routing_rule
set homeproxy.rr_gemini.label='5. Google Gemini'
set homeproxy.rr_gemini.enabled='1'
set homeproxy.rr_gemini.mode='default'
add_list homeproxy.rr_gemini.domain_suffix='gemini.google.com'
add_list homeproxy.rr_gemini.domain_suffix='bard.google.com'
add_list homeproxy.rr_gemini.domain_suffix='generativelanguage.googleapis.com'
add_list homeproxy.rr_gemini.domain_suffix='makersuite.google.com'
add_list homeproxy.rr_gemini.domain_suffix='deepmind.google'
add_list homeproxy.rr_gemini.domain_suffix='aistudio.google.com'
set homeproxy.rr_gemini.outbound='rn_gemini'

# 6. ChatGPT 专属代理
set homeproxy.rr_chatgpt=routing_rule
set homeproxy.rr_chatgpt.label='6. OpenAI ChatGPT'
set homeproxy.rr_chatgpt.enabled='1'
set homeproxy.rr_chatgpt.mode='default'
add_list homeproxy.rr_chatgpt.domain_suffix='openai.com'
add_list homeproxy.rr_chatgpt.domain_suffix='chatgpt.com'
add_list homeproxy.rr_chatgpt.domain_suffix='oaistatic.com'
add_list homeproxy.rr_chatgpt.domain_suffix='oaiusercontent.com'
add_list homeproxy.rr_chatgpt.domain_suffix='sora.com'
set homeproxy.rr_chatgpt.outbound='rn_chatgpt'

# 7. Claude 专属代理
set homeproxy.rr_claude=routing_rule
set homeproxy.rr_claude.label='7. Anthropic Claude'
set homeproxy.rr_claude.enabled='1'
set homeproxy.rr_claude.mode='default'
add_list homeproxy.rr_claude.domain_suffix='anthropic.com'
add_list homeproxy.rr_claude.domain_suffix='claude.ai'
set homeproxy.rr_claude.outbound='rn_claude'

# 8. 海外通用 AI
set homeproxy.rr_ai=routing_rule
set homeproxy.rr_ai.label='8. 海外通用 AI 服务'
set homeproxy.rr_ai.enabled='1'
set homeproxy.rr_ai.mode='default'
add_list homeproxy.rr_ai.rule_set='rs_ai'
set homeproxy.rr_ai.outbound='rn_ai'

# 9. 油管与流媒体
set homeproxy.rr_media=routing_rule
set homeproxy.rr_media.label='9. 海外流媒体与视频'
set homeproxy.rr_media.enabled='1'
set homeproxy.rr_media.mode='default'
add_list homeproxy.rr_media.rule_set='rs_youtube'
add_list homeproxy.rr_media.rule_set='rs_netflix'
add_list homeproxy.rr_media.rule_set='rs_netflixip'
add_list homeproxy.rr_media.rule_set='rs_disney'
add_list homeproxy.rr_media.rule_set='rs_max'
add_list homeproxy.rr_media.rule_set='rs_primevideo'
add_list homeproxy.rr_media.rule_set='rs_appletv'
add_list homeproxy.rr_media.rule_set='rs_spotify'
add_list homeproxy.rr_media.rule_set='rs_media'
add_list homeproxy.rr_media.rule_set='rs_mediaip'
set homeproxy.rr_media.outbound='rn_media'

# 10. 社交与通讯 (Telegram, Twitter, WhatsApp, TikTok)
set homeproxy.rr_social=routing_rule
set homeproxy.rr_social.label='10. 即时通讯与社交'
set homeproxy.rr_social.enabled='1'
set homeproxy.rr_social.mode='default'
add_list homeproxy.rr_social.rule_set='rs_tiktok'
add_list homeproxy.rr_social.rule_set='rs_telegramip'
add_list homeproxy.rr_social.domain_suffix='t.me'
add_list homeproxy.rr_social.domain_suffix='telegram.org'
add_list homeproxy.rr_social.domain_suffix='twitter.com'
add_list homeproxy.rr_social.domain_suffix='x.com'
add_list homeproxy.rr_social.domain_suffix='whatsapp.com'
set homeproxy.rr_social.outbound='rn_social'

# 11. GitHub
set homeproxy.rr_github=routing_rule
set homeproxy.rr_github.label='11. GitHub'
set homeproxy.rr_github.enabled='1'
set homeproxy.rr_github.mode='default'
add_list homeproxy.rr_github.domain_suffix='github.com'
add_list homeproxy.rr_github.domain_suffix='githubassets.com'
add_list homeproxy.rr_github.domain_suffix='githubusercontent.com'
set homeproxy.rr_github.outbound='rn_github'

# 12. 国内服务与 CDN 直连 (Google-CN, Apple-CN, MS-CN, Games-CN, Bilibili)
set homeproxy.rr_cn_services=routing_rule
set homeproxy.rr_cn_services.label='12. 国内服务直连加速'
set homeproxy.rr_cn_services.enabled='1'
set homeproxy.rr_cn_services.mode='default'
add_list homeproxy.rr_cn_services.rule_set='rs_googlecn'
add_list homeproxy.rr_cn_services.rule_set='rs_applecn'
add_list homeproxy.rr_cn_services.rule_set='rs_mscn'
add_list homeproxy.rr_cn_services.rule_set='rs_gamescn'
add_list homeproxy.rr_cn_services.rule_set='rs_bilibili'
set homeproxy.rr_cn_services.outbound='direct'

# 13. 游戏平台
set homeproxy.rr_games=routing_rule
set homeproxy.rr_games.label='13. 游戏平台 (Steam等)'
set homeproxy.rr_games.enabled='1'
set homeproxy.rr_games.mode='default'
add_list homeproxy.rr_games.rule_set='rs_games'
set homeproxy.rr_games.outbound='rn_games'

# 14. 测速工具
set homeproxy.rr_speedtest=routing_rule
set homeproxy.rr_speedtest.label='14. 网络测速'
set homeproxy.rr_speedtest.enabled='1'
set homeproxy.rr_speedtest.mode='default'
add_list homeproxy.rr_speedtest.rule_set='rs_networktest'
set homeproxy.rr_speedtest.outbound='direct'

# 15. GFW 与国外域名走代理
set homeproxy.rr_gfw=routing_rule
set homeproxy.rr_gfw.label='15. GFW与国外域名'
set homeproxy.rr_gfw.enabled='1'
set homeproxy.rr_gfw.mode='default'
add_list homeproxy.rr_gfw.rule_set='rs_gfw'
add_list homeproxy.rr_gfw.rule_set='rs_proxy'
add_list homeproxy.rr_gfw.rule_set='rs_tldproxy'
set homeproxy.rr_gfw.outbound='default-node'

# 16. 国内域名与国内 IP 直连
set homeproxy.rr_cn=routing_rule
set homeproxy.rr_cn.label='16. 国内域名与IP直连'
set homeproxy.rr_cn.enabled='1'
set homeproxy.rr_cn.mode='default'
add_list homeproxy.rr_cn.rule_set='rs_cn'
add_list homeproxy.rr_cn.rule_set='rs_cnip'
set homeproxy.rr_cn.outbound='direct'
EOF

# 提交更改
uci commit homeproxy

echo -e "\n${GREEN}[✔] 规则集与路由规则写入完成！${NC}"
echo -e "${YELLOW}[*] 正在重启 HomeProxy 服务以拉取规则并生效...${NC}"

if [ -f "/etc/init.d/homeproxy" ]; then
    /etc/init.d/homeproxy restart || /etc/init.d/homeproxy reload
    echo -e "${GREEN}[✔] HomeProxy 服务已成功重启！${NC}"
else
    echo -e "${YELLOW}[!] 请前往 OpenWrt 管理后台手动保存并应用 HomeProxy 配置。${NC}"
fi

echo -e "\n${BLUE}======================================================${NC}"
echo -e "${GREEN}恭喜！分流方案已成功部署。${NC}"
echo -e "如需调整具体分流走哪个节点，可随时在 LuCI 界面「客户端设置」-「路由规则」中修改对应规则的出站节点。"
echo -e "${BLUE}======================================================${NC}"
